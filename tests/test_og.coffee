should = require 'should'
sinon = require 'sinon'
OpenGraph = require '../src/index'
fs = require 'fs'

describe "og", ->
	before ->
		@youtubeHTML = fs.readFileSync "#{__dirname}/html/youtube.html", 'utf-8'
		@imgArrayHTML = fs.readFileSync "#{__dirname}/html/image-array.html", 'utf-8'

	describe "flat parser", ->

		before ->
			@og = new OpenGraph

		it "should properly decode basic types", (done) ->
			@og.getMetaFromHtml @youtubeHTML, (err, result) ->
				result.og.site_name.should.be.equal "YouTube"
				result.og.type.should.be.equal "video"
				done null

		it "should properly marge array types", (done) ->
			@og.getMetaFromHtml @youtubeHTML, (err, result) ->
				result.og['video:tag'].should.containEql "Nullo"
				result.og['video:height'].should.containEql "720"
				done null

	describe "tree parser", ->
		before ->
			@og = new OpenGraph {parseFlat:false}

		it "should properly decode basic types", (done) ->
			@og.getMetaFromHtml @youtubeHTML, (err, result) ->
				result.og.site_name.should.be.equal "YouTube"
				result.og.type.should.be.equal "video"
				done null

		it "should properly decode arrays", (done) ->
			@og.getMetaFromHtml @imgArrayHTML, (err, result) ->
				result.og.image.should.be.an.Array
				result.og.image.length.should.eql 3
				result.og.image[0].should.have.keys '__root', 'width', 'height'
				result.og.image[1].should.have.keys '__root'
				result.og.image[1].should.not.have.keys 'width', 'height'
				result.og.image[2].should.have.keys '__root', 'height'
				result.og.image[2].should.not.have.keys 'width'

				done null

		it "should properly decode YouTube arrays", (done) ->
			@og.getMetaFromHtml @youtubeHTML, (err, result) ->
				result.og.video.should.be.an.Array
				result.og.video[0].should.have.keys 'url', 'width', 'height', 'secure_url', 'type'

				done null