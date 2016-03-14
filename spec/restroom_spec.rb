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
      exposes :authors, class: Author do
        exposes :titles, class: Book, resource: :books, id: :key do
          set :response_filter, Proc.new { |data| data['data'] }
        end
      end
    end.dump

  end
end

describe Restroom do

  author_data = [
    { id: 1, name: 'Charlie Strauss' },
    { id: 2, name: 'William Gibson' }
  ]

  gibson_book_data = [
    { key: 'mona-list-overdrive', title: 'Mona Lisa Overdrive' }
  ]

  subject { Scifi::Client.new }

  before do
    stub_request(:get, "https://scifi.org/api/authors/2").
      with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Faraday v0.9.2'}).
      to_return(:status => 200, :body => JSON.dump(author_data[1]), :headers => {})

    stub_request(:get, "https://scifi.org/api/authors/2/books").
      with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Faraday v0.9.2'}).
      to_return(:status => 200, :body => JSON.dump(data: gibson_book_data), :headers => {})

    stub_request(:get, "https://scifi.org/api/authors").
      with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Faraday v0.9.2'}).
      to_return(:status => 200, :body => JSON.dump(author_data), :headers => {})

    stub_request(:get, "https://scifi.org/api/authors/2/books/mona-list-overdrive").
      with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Faraday v0.9.2'}).
      to_return(:status => 200, :body => JSON.dump(data: gibson_book_data.first), :headers => {})
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

  it "collects author's books" do
    expect(subject.authors.get(2).titles.all).to all( be_a(Book) )
    expect(subject.authors.get(2).titles.all.collect(&:title)) =~ gibson_book_data.collect{ |a| a[:title] }
  end

  it "collects a book" do
    expect(subject.authors.get(2).titles.get('mona-list-overdrive')).to be_a(Book)
    expect(subject.authors.get(2).titles.get('mona-list-overdrive').title).to eq('Mona Lisa Overdrive')
  end
end
