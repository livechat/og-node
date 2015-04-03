extractors =
	title: 
		name: "title"
		extract: ($, res, next) ->
			title = $('head > title').text()
			next null, title

	description:
		name: "description"
		extract: ($, res, next) ->
			description = $('meta[name="description"]').attr('content')
			next null, description

	image:
		name: "image"
		parseInlineCss: (css) ->
			parsed = {}

			try
				declarations = css.split ';'
				for declaration in declarations
					[key, value] = declaration.split ':'

					key = key.replace /\s/g, ''
					value = value.replace /\s/g, ''

					parsed[key] = value

			return parsed

		extract: ($, res, next) ->
			images = $('img')

			for img in images
				width = img.attribs.width
				height = img.attribs.height

				styles = @parseInlineCss img.attribs.style

				if not width and styles.width and /px/.test styles.width
					width = styles.width.split('px')[0]

				if not height and styles.height and /px/.test styles.height
					height = styles.height.split('px')[0]

				width = parseInt height, 10
				height = parseInt height, 10

				ratio = width / height

				if width > 200 && height > 200 && ratio < 2 and ratio > 0.5 and img.attribs.src
					image = img.attribs.src
					break

			next null, image
	
	explicitImage:
		name: 'explicitImage'
		extract: ($, res, next) ->
			if res.headers['content-type'] in ['image/png', 'image/jpg', 'image/jpeg']
				next null, res.request.href
			else
				next null

module.exports = extractors