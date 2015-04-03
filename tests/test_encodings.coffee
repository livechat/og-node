should = require 'should'
sinon = require 'sinon'
OpenGraph = require '../src/index'
fs = require 'fs'

describe "encodings", ->
	before ->
		@buffer = fs.readFileSync "#{__dirname}/html/encoding-iso-8859-2-no-meta.html", null

	beforeEach ->
		@og = new OpenGraph
		@og.getMetaFromHtml = sinon.stub().yields()

	describe "iso-8859-2", ->
		it "should decode using encoding from meta tag", ->
			buffer = fs.readFileSync "#{__dirname}/html/encoding-iso-8859-2.html", null

			@og.getMetaFromBuffer buffer, =>
				@og.getMetaFromHtml.calledOnce.should.be.true
				@og.getMetaFromHtml.lastCall.args[0].should.containEql "Róża wiatrów"

		it "should decode using encoding from server header", ->
			res = {headers: {'content-type': 'text/html; charset=ISO-8859-2'}}

			@og.getMetaFromBuffer @buffer, res, =>
				@og.getMetaFromHtml.calledOnce.should.be.true
				@og.getMetaFromHtml.lastCall.args[0].should.containEql "Róża wiatrów"

		it "should decode using default encoding when no encodings found", ->
			@og.getMetaFromBuffer @buffer, =>
				@og.getMetaFromHtml.calledOnce.should.be.true
				@og.getMetaFromHtml.lastCall.args[0].should.containEql "R��a wiatr�w"