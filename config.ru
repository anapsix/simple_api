require "rubygems"
require "sinatra"
require "bundler"

Bundler.require

require File.expand_path('../api.rb',__FILE__)

run MyAPI
