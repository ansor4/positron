_ = require 'underscore'
benv = require 'benv'
sinon = require 'sinon'
Article = require '../../../../../models/article'
Backbone = require 'backbone'
fixtures = require '../../../../../../test/helpers/fixtures'
{ resolve } = require 'path'

describe 'EditLayout', ->

  beforeEach (done) ->
    benv.setup =>
      tmpl = resolve __dirname, '../index.jade'
      benv.render tmpl, _.extend(fixtures().locals,
        article: @article = new Article fixtures().article
      ), =>
        benv.expose $: require('jquery')
        Backbone.$ = $
        sinon.stub Backbone, 'sync'
        @EditLayout = require '../index.coffee'
        sinon.stub @EditLayout.prototype, 'attachScribe'
        sinon.stub _, 'debounce'
        _.debounce.callsArg 0
        @view = new @EditLayout el: $('#layout-content'), article: @article
        @view.article.sync = sinon.stub()
        done()

  afterEach ->
    benv.teardown()
    Backbone.sync.restore()
    _.debounce.restore()
    @EditLayout::attachScribe.restore()

  describe '#autosave', ->

    it 'autosaves on debounce keyup', ->
      $('#edit-title input').trigger 'keyup'
      Backbone.sync.called.should.be.ok

    it 'autosaves on section changes', ->
      @view.article.sections.trigger 'change'
      Backbone.sync.called.should.be.ok

  describe 'on destroy', ->

    it 'redirects to the root', ->
      location.assign = sinon.stub()
      @view.article.destroy()
      location.assign.args[0][0].should.containEql '/articles?published='

  describe '#serialize', ->

    it 'turns form elements into data', ->
      @view.$('#edit-thumbnail-title :input').val('foobar')
      @view.serialize().thumbnail_title.should.equal 'foobar'

    it 'cleans up tags into an array', ->
      @view.$('#edit-thumbnail-tags input').val('foobar,baz,boo   bar,bam  ')
      @view.serialize().tags.should.eql [
        'foobar', 'baz', 'boo bar', 'bam'
      ]

  describe '#attachScribe', ->

    it 'attaches Scribe to the lead paragraph'

  describe '#toggleLeadParagraphPlaceholder', ->

    it 'toggle the placeholder ::before element if lead paragraph is empty', ->
      $('#edit-lead-paragraph').html "<p>foobar</p>"
      @view.toggleLeadParagraphPlaceholder()
      $('#edit-lead-paragraph').hasClass('is-empty').should.not.be.ok
      $('#edit-lead-paragraph').html "<p><br></p>"
      @view.toggleLeadParagraphPlaceholder()
      $('#edit-lead-paragraph').hasClass('is-empty').should.be.ok

  describe '#popLockControls', ->

    it 'locks the controls to the top when you scroll', ->
      @view.$window = scrollTop: -> 100
      @view.$el.append( $section = $
        "<div class='edit-section-container' data-state-editing='true'>
          <div class='edit-section-controls'></div>
        </div>"
      )
      @view.popLockControls()
      $($section.find('.edit-section-controls')).attr('data-fixed')
        .should.equal 'true'

  describe '#togglePublished', ->

    it 'publishes an article thats ready', ->
      @view.article.set
        title: 'foo'
        thumbnail_title: 'bar'
        thumbnail_image: 'foo.jpg'
        thumbnail_teaser: 'baz'
        tags: ['foo']
      @view.article.save = sinon.stub()
      @view.togglePublished { preventDefault: (->), stopPropagation: (->) }
      @view.article.save.called.should.be.ok

    it 'highlights missing fields if not done', ->
      @view.article.clear()
      @view.togglePublished { preventDefault: (->), stopPropagation: (->) }
      @view.$('#edit-thumbnail-inputs').hasClass('eti-error').should.be.ok