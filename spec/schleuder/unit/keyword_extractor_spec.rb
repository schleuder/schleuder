require 'spec_helper'

describe Schleuder::KeywordExtractor do
  context '#extract_keywords' do
    it 'reads multiple lines as keyword arguments, but only as many as specified by the keyword handler' do
      string = "x-subscribe: first\nsecond\nthird\n0xblafoo\ntralafiti\n"
      m = Mail.new
      m.body = string
      list = create(:list)
      m = Mail.create_message_to_list(m, list.request_address, list)

      keywords = m.keywords

      expect(keywords.size).to eql(1)
      expect(keywords.first.arguments.size).to eql(4)
      expect(m.body.to_s).to eql("tralafiti\n")
    end

    it 'takes any content as keyword argument if the keyword handler specifies it' do
      string = "x-add-key: first\nsecond\nthird\n\n\nok\ntralafiti\n"
      m = Mail.new
      m.body = string
      list = create(:list)
      m = Mail.create_message_to_list(m, list.request_address, list)

      keywords = m.keywords

      expect(keywords.size).to eql(1)
      expect(keywords.first.arguments.size).to eql(5)
      expect(m.body.to_s).to eql('')
    end

    it 'takes any content — up to the next keyword — as keyword argument if the keyword handler specifies it' do
      string = "x-add-key: first\nsecond\nthird\n\n\nok\nx-list-keys: tralafiti\n"
      m = Mail.new
      m.body = string
      list = create(:list)
      m = Mail.create_message_to_list(m, list.request_address, list)

      keywords = m.keywords

      expect(keywords.size).to eql(2)
      expect(keywords.first.arguments.size).to eql(4)
      expect(keywords.last.arguments.size).to eql(1)
      expect(m.body.to_s).to eql('')
    end

    it 'drops empty lines in keyword arguments parsing' do
      string = "x-something: first\nthird\nx-somethingelse: ok\nx-stop\ntralafiti\n"
      m = Mail.new
      m.body = string
      m.to_s

      keywords = m.keywords

      expect(keywords).to eql([['something', ['first', 'third']], ['somethingelse', ['ok']], ['stop', []]])
      expect(m.body.to_s).to eql("tralafiti\n")
    end

    it 'splits lines into words and downcases them in keyword arguments' do
      string = "x-something: first\nSECOND     end\nthird\nx-somethingelse: ok\nx-stop\ntralafiti\n"
      m = Mail.new
      m.body = string
      m.to_s

      keywords = m.keywords

      expect(keywords).to eql([['something', ['first', 'second', 'end', 'third']], ['somethingelse', ['ok']], ['stop', []]])
      expect(m.body.to_s).to eql("tralafiti\n")
    end
  end

