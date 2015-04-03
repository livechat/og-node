should = require 'should'
sinon = require 'sinon'
OpenGraph = require '../src/index'
fs = require 'fs'

describe "extractor", ->
	beforeEach ->
		@og = new OpenGraph
		@youtubeHTML = fs.readFileSync "#{__dirname}/html/youtube.html", 'utf-8'
		@imageHTML = fs.readFileSync "#{__dirname}/html/image-array.html", 'utf-8'

	describe "basic", ->
		it "should properly register extractor", ->
			@og.registerExtractor OpenGraph.extractors.title
			@og.extractors.length.should.eql 1
			@og.registerExtractor OpenGraph.extractors.image
			@og.extractors.length.should.eql 2

		it "shouldn't register bad extractor", ->
			@og.registerExtractor.bind(@og).should.throw "Bad extractor format!"

		it "shouldn't duplicate extractors", ->
			@og.registerExtractor OpenGraph.extractors.title
			@og.registerExtractor.bind(@og, OpenGraph.extractors.title).should.throw "Extractor name duplication: title"

		it "shouldn't crash when extractor throws", (done) ->
			@og.registerExtractor OpenGraph.extractors.explicitImage

			@og.getMetaFromHtml "", null, (err, results) ->
				err.should.not.be.null
				done null

	describe "results", ->
		it "should return page title", (done) ->
			@og.registerExtractor OpenGraph.extractors.title
			@og.getMetaFromHtml @youtubeHTML, (err, results) ->
				results.custom.title.should.startWith "Trzeci Wymiar - Murmurando"
				done null

		it "should return page description", (done) ->
			@og.registerExtractor OpenGraph.extractors.description
			@og.getMetaFromHtml @youtubeHTML, (err, results) ->
				results.custom.description.should.startWith "Kup album Trzeci Wymiar"
				done null

		it "should detect explicit image url", (done) ->
			@og.registerExtractor OpenGraph.extractors.explicitImage

			res = {headers: {'content-type': 'image/jpg'}, request: {href:'http://path.to/image.jpg'}}

			@og.getMetaFromHtml "", res, (err, results) ->
				results.custom.explicitImage.should.startWith "http://path.to/image.jpg"
				done null


		it "should detect image url", (done) ->
			@og.registerExtractor OpenGraph.extractors.image

			@og.getMetaFromHtml @imageHTML, (err, results) ->
				results.custom.image.should.startWith "https://path.to/image.2.jpeg"
				done null