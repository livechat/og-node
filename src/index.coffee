cheerio = require 'cheerio'
_ = require 'underscore'
request = require 'request'
iconv = require 'iconv-lite'
async = require 'async'

class OpenGraph
	ALLOWED_CONTENT_TYPES = ['text/html', 'image/png', 'image/jpeg', 'image/jpg']

	constructor: (options = {}) ->
		@options = _.defaults options, 
			parseFlat: true # set to false for experimental arrays parsing
			encoding: null # use null for auto detection
			followRedirect: true
			followAllRedirects: false
			maxRedirects: 3
			timeout: 15 * 1000
			gzip: true
			headers:
				'User-Agent': "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2272.104 Safari/537.36"
			pool:
				maxSockets: Infinity

		@extractors = []

	registerExtractor: (extractor) ->
		unless extractor and _.isString(extractor.name) and extractor.name.length and _.isFunction(extractor.extract)
			throw new Error("Bad extractor format!")

		if extractor.name in _.pluck(@extractors, 'name')
			throw new Error("Extractor name duplication: #{extractor.name}", )

		@extractors.push extractor

	getEncoding = (header) ->
		try
			declarations = header.split ';'

			for declaration in declarations
				[key, value] = declaration.split '='
				key = try key.replace /\s/g, ''
				value = try value.replace /\s/g, ''

				if key and key.toLowerCase() is 'charset'
					return value

		return null

	getMetaFromUrl: (url, callback) =>
		callback = _.once callback

		theRequest = request.get _.extend({url: url}, @options), (err, res, body) =>
			theRequest.removeAllListeners 'response' if theRequest
			if err then return callback err

			if Buffer.isBuffer body
				@getMetaFromBuffer body, res, callback
			else
				@getMetaFromHtml body, res, callback

		theRequest.once 'response', openGraphResponseHandler = (res) ->
			contentDisposition = res.headers['content-disposition']
			contentType = res.headers['content-type'] || ''
			[contentType] = contentType.split ';'
			contentLength = res.headers['content-length']

			if res.statusCode >= 400
				theRequest.abort()
				return callback "status code #{res.statusCode}, aborted"

			if contentDisposition and /^attachment/.test contentDisposition
				theRequest.abort()
				return callback "downloadable content, aborted"

			if contentType.toLowerCase() not in ALLOWED_CONTENT_TYPES
				theRequest.abort()
				return callback "bad content type, aborted"

			if contentLength and parseInt(contentLength, 10) > 10 * 1024 * 1024
				theRequest.abort()
				return callback "response size over 10M, aborted"

	getMetaFromBuffer: (buffer, res, callback) =>
		unless callback then callback = res

		asciiHtml = buffer.toString 'ascii'
		
		$ = try cheerio.load asciiHtml catch e
		if e then return callback e

		encoding = try getEncoding res.headers['content-type']

		unless encoding
			metaTags = try $('meta[http-equiv]') catch e
			if e then return callback e

			for metaTag in metaTags
				if metaTag.attribs['http-equiv'].toLowerCase() is 'content-type'
					encoding = getEncoding metaTag.attribs.content

		encoding ?= "utf-8"

		if encoding.toLowerCase() in ['utf-8', 'utf8', null] then encoding = 'utf-8'

		try
			html = iconv.decode buffer, encoding
		catch e
			return callback e

		@getMetaFromHtml html, res, callback

	getMetaFromHtml: (html, res, callback) ->
		unless callback then callback = res

		parsed =
			og: {}
			custom: {}

		$ = try cheerio.load html catch e
		if e then return callback e

		# --- open graph ---
		namespace = null

		html = try $('html')[0]

		if html?.attribs
			for attrName of html.attribs
				attrValue = html.attribs[attrName] 

				if attrValue.toLowerCase() is 'http://opengraphprotocol.org/schema/' and attrName.substring(0,6) is 'xmlns:'
					namespace = attrName.substring(6)
					break

		namespace ?= 'og'
		namespace += ':'

		metaTags = try $("meta") catch e
		if e then return callback e

		for meta in metaTags
			properties = _.pick meta.attribs, 'property', 'content'
			unless properties.property and properties.property.substring(0, namespace.length) is namespace
				continue

			property = properties.property.substring(namespace.length)

			if @options.parseFlat

				if _.isArray(parsed.og[property])
					parsed.og[property].push properties.content
				else if parsed.og[property]
					parsed.og[property] = [parsed.og[property], properties.content]
				else 
					parsed.og[property] = properties.content

			else
				createTree = (ref, keys) ->
					key = keys.shift()

					if keys.length
						if _.isString ref[key]
							ref[key] = [__root: ref[key]]
						else 
							ref[key] ?= []
					else
						if _.isArray(ref) and not ref.length
							obj = {}
							obj[key] = properties.content
							ref.push obj
						else if _.isArray(ref) and not ref[ref.length - 1][key]
							ref[ref.length - 1][key] = properties.content
						else if _.isArray(ref) and ref[ref.length - 1][key]
							obj = {}
							obj[key] = properties.content
							ref.push obj

						else if _.isArray ref[key]
							ref[key].push
								__root: properties.content
						else
							ref[key] = properties.content

					if keys.length then createTree ref[key], keys

				createTree parsed.og, property.split ":"

		# --- custom ---

		async.each @extractors, (extractor, next) ->
			try
				extractor.extract $, res, (err, value) ->
					if err then return next err
					parsed.custom[extractor.name] = value if value
					# setImmediate exits try scope
					setImmediate -> next null	
			catch e
				setImmediate -> next "extractor #{extractor.name} thrown: #{e}"

		, (error) -> callback error, parsed

OpenGraph.extractors = require './extractors'

module.exports = OpenGraph