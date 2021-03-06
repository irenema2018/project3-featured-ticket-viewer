     
require "sinatra"
require "sinatra/reloader"
require "httparty"
require_relative 'function'

enable  :sessions

get '/' do
  erb :index
end

get '/error' do
  erb :error
end

get '/tickets' do
  session[:error_message] = 'Something was wrong. Please go back to Home and try again!' 
  redirect '/error'
end

post '/tickets' do
  # According to https://www.zendesk.com/register/free-trial/#subdomain
  if params[:accountname].length < 3 || # Domain must be at least 3 characters.
    params[:accountname].match(/[^0-9a-z-]/) # Symbols except dash(-) are not allowed.
     
    session[:error_message] = 'Something was wrong with your account name. Please go back to Home and try again!'
    redirect '/error'
  end

  session[:accountname] = params[:accountname]
  session[:email]       = params[:email]
  session[:password]    = params[:password]

  url = "https://#{session[:accountname]}.zendesk.com/api/v2/tickets.json?per_page=25&include=users"

  response = send_api_request(url)

  @tickets = response['tickets']
  session[:next_page_url] = response['next_page']
  session[:prev_page_url] = response['previous_page']
  @count = response['count']
  @users = create_user_object(response['users'])

  erb :tickets
end

get '/tickets/page/:page' do
  url = "https://#{session[:accountname]}.zendesk.com/api/v2/tickets.json?include=users&page=#{params[:page]}&per_page=25"

  access_to_different_page(url)
  erb :tickets
end

get '/ticket/:id' do
  if !session[:accountname]
    session[:error_message] = "Unable to get ticket ##{params[:id]}."
    redirect '/error'
  end

  url = "https://#{session[:accountname]}.zendesk.com/api/v2/tickets/#{params[:id]}.json?include=users"
  response = send_api_request(url)
       
  @ticket = response['ticket']
  @id = @ticket['id']
  @users = create_user_object(response['users'])
  erb :ticket
end









