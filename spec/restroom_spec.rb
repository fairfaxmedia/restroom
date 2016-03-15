require 'spec_helper'
require 'json'
require 'ostruct'

Author, Book = Class.new(OpenStruct), Class.new(OpenStruct)

class Authlet < Faraday::Middleware
  def initialize(app)
    @app = app
  end

  def call(env)
    env[:request_headers]['AUTH_HEADER']= 'token'
    @app.call env
  end
end

Faraday::Request.register_middleware authlet: lambda { Authlet }

module Scifi
  class Client
    include Restroom

    def self.stack(config)
      config.request :authlet
    end

    restroom 'https://scifi.org', base_path: 'api' do
      exposes :authors do
        exposes :influences, model: Author, response_filter: Proc.new { |data| data['influences'] }
        exposes :titles, model: Book, resource: :books, id: :key do
          response_filter Proc.new { |data| data['data'] }
        end
      end
    end.dump

  end
end

describe Restroom do

  author_data = [
    { id: 1, name: 'Charlie Strauss' },
    { id: 2, name: 'William Gibson' },
    { id: 3, name: 'William S. Burroughs' }
  ]

  gibson_book_data = [
    { key: 'mona-list-overdrive', title: 'Mona Lisa Overdrive' }
  ]

  subject { Scifi::Client.new }

  before do
    stub_request(:get, "https://scifi.org/api/authors").
      with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Faraday v0.9.2'}).
      to_return(:status => 200, :body => JSON.dump(author_data), :headers => {})

    stub_request(:get, "https://scifi.org/api/authors/2").
      with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Faraday v0.9.2'}).
      to_return(:status => 200, :body => JSON.dump(author_data[1]), :headers => {})

    stub_request(:get, "https://scifi.org/api/authors/2/books").
      with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Faraday v0.9.2'}).
      to_return(:status => 200, :body => JSON.dump(data: gibson_book_data), :headers => {})

    stub_request(:get, "https://scifi.org/api/authors/2/influences").
      with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Faraday v0.9.2'}).
      to_return(:status => 200, :body => JSON.dump(influences: [author_data[3]]), :headers => {})

    stub_request(:get, "https://scifi.org/api/authors/2/books/mona-list-overdrive").
      with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Faraday v0.9.2'}).
      to_return(:status => 200, :body => JSON.dump(data: gibson_book_data.first), :headers => {})

    stub_request(:get, "https://scifi.org/api/authors/3").
      with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Faraday v0.9.2'}).
      to_return(:status => 500, :body => "*bzzt*", :headers => {})

    stub_request(:get, "https://scifi.org/api/authors/4").
      with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Faraday v0.9.2'}).
      to_timeout

    stub_request(:get, "https://scifi.org/api/authors/5").
      with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Faraday v0.9.2'}).
      to_return(:status => 403, :body => 'Who are you?', :headers => {})
  end

  context "for authors" do
    context "the plural path" do
      it "is returning a list of author objects" do
        expect(subject.authors.all).to all( be_a(Author) )
      end

      it "is returning objects with the right ids" do
        expect(subject.authors.all.collect(&:id)) =~ author_data.collect{ |a| a[:id] }
      end
    end

    context "for the singular path" do
      it "is returning an author object" do
        expect(subject.authors.get(2)).to be_a(Author)
      end

      it "is returning the right author title" do
        expect(subject.authors.get(2).name).to eq('William Gibson')
      end
    end
  end

  it "collects author's influences" do
    expect(subject.authors.get(2).influences.all).to all( be_a(Author) )
    expect(subject.authors.get(2).influences.all.collect(&:name)) =~ ['William S. Burroughs']
  end

  it "collects author's books" do
    expect(subject.authors.get(2).titles.all).to all( be_a(Book) )
    expect(subject.authors.get(2).titles.all.collect(&:title)) =~ gibson_book_data.collect{ |a| a[:title] }
  end

  it "collects a book" do
    expect(subject.authors.get(2).titles.get('mona-list-overdrive')).to be_a(Book)
    expect(subject.authors.get(2).titles.get('mona-list-overdrive').title).to eq('Mona Lisa Overdrive')
  end

  it "handles a server error gracefully" do
    expect { subject.authors.get(3) }.to raise_error(Restroom::ApiError)
  end

  it "handles a network error gracefully" do
    expect { subject.authors.get(4) }.to raise_error(Restroom::NetworkError)
  end

  it "handles an authentication error gracefully" do
    expect { subject.authors.get(5) }.to raise_error(Restroom::AuthenticationError)
  end
end
