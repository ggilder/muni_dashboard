require 'sinatra'

get '/' do
	@@var ||= rand 1000
	"Hello there, world #{@@var}, ain't you lookin' fine today."
end