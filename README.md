
Sessions and Cookies Presentation
Project 1 Flatiron School 
Maureen Johnston
Michael Teja


There are many things that we, as developers, rely on without giving it too much thought. They are taken care of by libraries that we use. The logic is abstracted for you, but it’s important to understand how the libraries we uses implements those structures so we understand security tradeoffs that might not be obvious otherwise.

HTTP is a Stateless Protocol

HTTP is a “stateless protocol”. This means that by default, any two requests are handled completely independently, regardless if they come from the same address, request the same resource, or are sent in quick succession. This leaves all applications with the responsibility to provide some degree of state management.



Cookies, Sessions, and Flashes
Cookies, Sessions and Flashes are three special objects that Rails 4 gives you which each behave a lot like hashes. They are used to persist data between requests, whether until just the next request, until the browser is closed, or until a specified expiration has been reached. In addition to different temporal concerns, they each solve slightly different use cases.


Server Application / Session
"Sessions" are the idea that your user's state is somehow preserved when he/she clicks from one page to the next. Ginven that, HTTP is stateless, it's up to either the browser or your application to "remember" what needs to be remembered.

Most web servers don’t just return a resource; they do some some sort of processing on the incoming request through an application or a script. As long as these things are left running, some state can be stored in the application’s RAM. The most common example of this is called a “session”. With sessions the server application designates a section of RAM to hold an arbitrary amount of state data. The application then passes a single token to the client, who is responsible for saving that token and attaching it every future request (for the duration of the session). Sessions are best used to maintain per-visit state. 

Applicable for storing: shopping cart checkout progress, order customization, user profile and other data cached from a database.

Sessions
Think about how websites keep track of how a user is logged in when the page reloads. HTTP requests are stateless so how can you tell that a given request actually came from that particular user who is logged in? This is why cookies are important -- they allow you to keep track of your user from one request to another until the cookie expires.

A special case is when you want to keep track of data in the user's "session", which represents all the stuff your user does while you've chosen to "remember" her, typically until the browser window is closed. In that case, every page she visits until the browser is closed will be part of the same session.


    ...



Cookie






















Cookies are small pieces of text, stored on the client machine (or browser). Because of this, they can survive a server reboot or reconfiguration, but they will not follow a user to a different computer or browser so they can be lost somewhat easily. Many user agents also disable cookies by default. Cookies have received a lot of flack recently because they can be configured to be read across different domains, leading to concerns about tracking and privacy in advertising.
Cookies
Cookies are key-value data pairs that are stored in the user's browser until they reach their specified expiration date. They can be used for pretty much anything, most commonly to "bookmark" the user's place in a web page if she gets disconnected or to store simple site display preferences. You could also store shopping cart information or even passwords but that would be a bad idea -- you shouldn't store anything in regular browser cookies that needs to either be secure or persisted across browser sessions. It's too easy for users to clear their cache and/or steal/manipulate unsecured cookies.

            ….
Cookies + Sessions = ♥

Rails uses a CookieStore to handle sessions. What it means is that all the informations needed to identify a user's session is sent to the client and nothing is stored on the server. When a user sends a request, the session's cookie is processed and validated so rails, warden, devise, etc. can figure out who you are and instantiate the correct user from the database.

Like I said earlier, cookies are how server can remember who you are from one request to another. Everytime you send a request to a server, you send every cookie you have for that domain. A session cookie is signed and encrypted (encryption is new in Rails 4) then sent to the browser. That cookie is actually a hash that would look like this if you run something like Warden and Devise:


cookie = {
  "session_id": "Value",
  "_csrf_token": "token",
  "user_id": "1"
}


                    …..
Encryption & Signature





Type to enter text



From the hash above, the cookie will become an encrypted and signed string that will then be sent to the client's browser in a Base64 format. Encryption is done with :

ActiveSupport::MessageEncryptor and the signature is done with ActiveSupport::MessageVerifier.

Those are the two gatekeepers for your application, if they are compromised, someone could log in as anyone. This is why Ruby on rails' guide specifies to use strong secrets for your session keys.



Encryption

You are probably used to key-derivation encryption (bcrypt, pbkdf2, etc). While these are useful for passwords, they are useless here because key-derivation functions cannot be decrypted (that's on purpose). Cookies, on the other hand, need to be decrypted when they are received to extract the content and assign the user to the request. So instead of a key-derivation function, rails uses a cipher (by default aes-256-cbc) to encrypt and decrypt the content.

Signature

Signature is appended to the serialized content of the cookie. First, the hash above is converted to a string, then rails append "--" to the end of the string and then append a signature that makes that the content of the cookie was not altered. Basically, what it does is it takes a secret token and make an hexadecimal digest of the token and the cookie (as a string). It's important to note that signing a cookie is merely appending an hexadecimal string to the end of the cookie's value. A user can read the data off your cookie if your cookie is not encrypted (they aren't prior to rails 4!).

Session id are not stored nor validated on the server side

I said earlier that everything was sent to the client and nothing was kept. By default, rails does not store the session id on the server. So, when the request is received, the cookies is decrypted and the signature is verified but the session id's verification is only made to make sure it exists. As far as rails is concerned the session id can be anything. Heck, every user could have the same session id and it wouldn't change a thing.

There's more than one storage type

By default, rails uses the cookie storage and it works fine for most of us. But if you want to store the session id, you have alternatives that works just as good. To change session storage, you need to change it in the configuration.


# config/environments/{production|development|test}.rb
YourApp::Application.configure do
  config.session_store = ActionDispatch::Sessions::CacheStore
end

The three storage that are available to you:

ActionDispatch::Sessions::CookieStore (default)
ActionDispatch::Sessions::CacheStore
ActionDispatch::Sessions::MemCacheStore
It's important to note that the last two stores will save the session id to the cookie unencrypted and unsigned.

            ….

Why would you need both cookies and sessions? They are similar but not the same. session is an entire hash that gets put in the secure session cookie that expires when the user closes the browser. If you look in your developer tools, the "expiration" of that cookie is "session". Each value in the cookies hash gets stored as an individual cookie.

So cookies and sessions are sort of like temporary free database tables for you to use that are unique to a given user and will last until you either manually delete them, they have reached their expiration date, or the session is ended (depending on what you specified).


                        ….

Flashes
You've already seen and used the flash hash by now, but we'll cover it again from the perspective of understanding sessions. flash is a special hash (okay, a method that acts like a hash) that persists only from one request to the next. You can think of it as a session hash that self destructs after it's opened. It's commonly used to send messages from the controller to the view so the user can see success and failure messages after submitting forms.

If you want to pop up "Thanks for signing up!" on the user's browser after running the #create action (which usually uses redirect_to to send the user to a totally new page when successful), how do you send that success message? You can't use an instance variable because the redirect caused the browser to issue a brand new HTTP request and so all instance variables were lost.

The flash is there to save the day! Just store flash[:success] (or whatever you'd like it called) and it will be available to your view on the next new request. As soon as the view accesses the hash, Rails erases the data so you don't have it show up every time the user hits a new page. So clean, so convenient.

What about cases where the user can't sign up because of failed validations? In this case, the typical #create action would just render the #new action using the existing instance variables. Since it's not a totally new request, you'll want to have your error message available immediately. That's why there's the handy flash.now hash, e.g. flash.now[:error] = "Fix your submission!". Just like the regular flash, this one self destructs automatically after opening.

You still have to write view code to display the flash messages. It's common to write a short view helper that will pin any available flash message(s) to the top of the browser. You might also add a class to the message which will allow you to write some custom CSS, for instance turning :success messages green and :error messages red.

…

    # app/views/layouts/application.html.erb
    ...
    <% flash.each do |name, message| %>
      <div class="<%= name %>"><%= message %></div>
    <% end %>

…


                        …..

Controller Filters

Before we talk about authentication, we need to cover controller filters. The idea of these filters is to run some code in your controller at very specific times, for instance before any other code has been run. That's important because, if a user is requesting to run an action they haven't been authorized for, you need to nip that request in the bud and send back the appropriate error/redirect before they're able to do anything else. You're basically "filtering out" unauthorized requests.

We do this through the use of a "before filter", which takes the name of the method we want to run:

    # app/controllers/users_controller
    before_action :require_login
    ...
    private
    def require_login
      # do stuff to check if user is logged in
    end
The before_action method takes the symbol of the method to run before anything else gets run in the controller. If it returns false or nil, the request will not succeed.

You can specify to only apply the filter for specific actions by specifying the only option, e.g. before_action :require_login, :only => [:edit, :update]. The opposite applies by using the :except option... it will run for all actions except those specified.

You'll want to hide your filter methods behind the private designation so they can only be used by that controller.

Finally, filters are inherited so if you'd like a filter to apply to absolutely every controller action, put it in your app/controllers/application_controller.rb file.


                    …..


Authentication



The whole point of authentication is to make sure that whoever is requesting to run an action is actually allowed to do so. The standard way of managing this is through logging in your user via a sign in form. Once the user is logged in, you keep track of that user using the session until the user logs out.

A related concept is authorization. Yes, you may be signed in, but are you actually authorized to access what you're trying to access? The typical example is the difference between a regular user and an admin user. They both authenticate with the system but only the admin is authorized to make changes to certain things.

Authentication and authorization go hand in hand -- you first authenticate someone so you know who they are and can check if they're authorized to view a page or perform an action. When you build your app, you'll have a system of authentication to get the user signed in and to verify the user is who he says he is. You authorize the user to do certain things (like delete stuff) based on which methods are protected by controller filters that require signin or elevated permissions (e.g. admin status).

Basic and Digest Authentication
If you're looking for a very casual and insecure way of authenticating people, HTTP Basic authentication can be used. It involves submitting a username and password to a simple form and sending it (unencrypted) across the network. You use the #http_basic_authenticate_with method to do so and to restrict access to certain controllers without it.

For a slightly more secure (over HTTP) authentication system, use HTTP Digest Authentication. It relies on a #before_action running a method which calls upon #authenticate_or_request_with_http_digest, which takes a block that should return the "correct" password that should have been provided.

The problem with both of these is that they hard code user names and passwords in your controller (or somewhere), so it's really just a band-aid solution.


                    …..

Controller Filters

Before we talk about authentication, we need to cover controller filters. The idea of these filters is to run some code in your controller at very specific times, for instance before any other code has been run. That's important because, if a user is requesting to run an action they haven't been authorized for, you need to stop it and send back the appropriate error/redirect before they're able to do anything else. You're basically "filtering out" unauthorized requests.

We do this through the use of a "before filter", which takes the name of the method we want to run:

…
    # app/controllers/users_controller
    before_action :require_login
    ...
    private
    def require_login
      # do stuff to check if user is logged in
    end
…


The before_action method takes the symbol of the method to run before anything else gets run in the controller. If it returns false or nil, the request will not succeed.

You can specify to only apply the filter for specific actions by specifying the only option:

before_action :require_login, :only => [:edit, :update]. 

The opposite applies by using the :except option... it will run for all actions except those specified.

You'll want to hide your filter methods behind the private designation so they can only be used by that controller.

Finally, filters are inherited so if you'd like a filter to apply to absolutely every controller action, put it in your app/controllers/application_controller.rb file.

Authentication

The whole point of authentication is to make sure that whoever is requesting to run an action is actually allowed to do so. The standard way of managing this is through logging in your user via a sign in form. Once the user is logged in, you keep track of that user using the session until the user logs out.

A related concept is authorization. Yes, you may be signed in, but are you actually authorized to access what you're trying to access? The typical example is the difference between a regular user and an admin user. They both authenticate with the system but only the admin is authorized to make changes to certain things.

Authentication and authorization go hand in hand -- you first authenticate someone so you know who they are and can check if they're authorized to view a page or perform an action. When you build your app, you'll have a system of authentication to get the user signed in and to verify the user is who he says he is. You authorize the user to do certain things (like delete stuff) based on which methods are protected by controller filters that require signin or elevated permissions (e.g. admin status).



Basic and Digest Authentication

If you're looking for a very casual and insecure way of authenticating people, HTTP Basic authentication can be used. It basically involves submitting a username and password to a simple form and sending it (unencrypted) across the network. You use the #http_basic_authenticate_with method to do so and to restrict access to certain controllers without it.

For a slightly more secure (over HTTP) authentication system, use HTTP Digest Authentication. It relies on a #before_action running a method which calls upon #authenticate_or_request_with_http_digest, which takes a block that should return the "correct" password that should have been provided.

The problem with both of these is that they hard code user names and passwords in your controller (or somewhere), so it's really just a band-aid solution.








…………………………………………………………………………………….


Simple Authentication with Bcrypt
This tutorial is for adding authentication to a vanilla Ruby on Rails app using Bcrypt and has_secure_password.

The steps below are based on Ryan Bates's approach from Railscast #250 Authentication from Scratch (revised).

You can see the final source code here: repo. I began with a stock rails app using rails new gif_vault

Steps

Create a user model with a name, email and password_digest (all strings) by entering the following command into the command line: rails generate model user name email password_digest.

Note: If you already have a user model or you're going to use a different model for authentication, that model must have an attribute names password_digest and some kind of attribute to identify the user (like an email or a username).

Run rake db:migrate in the command line to migrate the database.
Add these routes below to your routes.rb file. Notice I also deleted all the comments inside that file. Don't forget to leave the trailing end, though.

# config/routes.rb

GifVault::Application.routes.draw do

    # This route sends requests to our naked url to the *cool* action in the *gif* controller.
    root to: 'gif#cool'

    # I've created a gif controller so I have a page I can secure later. 
    # This is optional (as is the root to: above).
    get '/cool' => 'gif#cool'
    get '/sweet' => 'gif#sweet'

    # These routes will be for signup. The first renders a form in the browse, the second will 
    # receive the form and create a user in our database using the data given to us by the user.
    get '/signup' => 'users#new'
    post '/users' => 'users#create'

end
Create a users controller:

# app/controllers/users_controller.rb

class UsersController < ApplicationController

end
Add a new action (for rendering the signup form) and a create action (for receiving the form and creating a user with the form's parameters.):

# app/controllers/users_controller.rb

class UsersController < ApplicationController

    def new
    end

    def create
    end   

end
Now create the view file where we put the signup form.

<!-- app/views/users/new.html.erb -->

<h1>Signup!</h1>

<%= form_for :user, url: '/users' do |f| %>

  Name: <%= f.text_field :name %>
  Email: <%= f.text_field :email %>
  Password: <%= f.password_field :password %>
  Password Confirmation: <%= f.password_field :password_confirmation %>
  <%= f.submit "Submit" %>

<% end %>
A note on Rail's conventions: This view file is for the new action of the users controller. As a result, we save the file here: /app/views/users/new.html.erb. The file is called new.html.erb and it is saved inside the views folder, in a folder we created called users.

That's the convention: view files are inside a folder with the same name as the controller and are named for the action they render.

Add logic to create action and add the private user_params method to sanitize the input from the form (this is a new Rails 4 thing and it's required). You might need to adjust the parameters inside the .permit() method based on how you setup your User model.

class UsersController < ApplicationController

  def new
  end

  def create
    user = User.new(user_params)
    if user.save
      session[:user_id] = user.id
      redirect_to '/'
    else
      redirect_to '/signup'
    end
  end

private

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end
end
Go to your Gemfile and uncomment the 'bcrypt' gem. We need bcrypt to securely store passwords in our database.

source 'https://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.0.4'

# Use sqlite3 as the database for Active Record
gem 'sqlite3'

...

# Use ActiveModel has_secure_password
gem 'bcrypt', '~> 3.1.7'

...
Go to the User model file and add has_secure_password. This is the line of code that gives our User model authentication methods via bcrypt.

# app/models/user.rb

class User < ActiveRecord::Base

  has_secure_password

end
Run bundle install from the terminal then restart your rails server.

Note: Windows users might have issues with bcrypt. If so, copy the error into Google and look for answers on Stack Overflow. There is documentation online for how to fix Windows so the bcrypt works.

Create a sessions controller. This is where we create (aka login) and destroy (aka logout) sessions.

# app/controllers/sessions_controller.rb

class SessionsController < ApplicationController

  def new
  end

  def create
  end

  def destroy
  end

end
Create a form for user's to login with.

<!-- app/views/sessions/new.html.erb -->

<h1>Login</h1>

<%= form_tag '/login' do %>

  Email: <%= text_field_tag :email %>
  Password: <%= password_field_tag :password %>
  <%= submit_tag "Submit" %>

<% end %>
Update your routes file to include new routes for the sessions controller.

GifVault::Application.routes.draw do

  root to: 'gif#cool'

  # these routes are for showing users a login form, logging them in, and logging them out.
  get '/login' => 'sessions#new'
  post '/login' => 'sessions#create'
  get '/logout' => 'sessions#destroy'

  get '/signup' => 'users#new'
  post '/users' => 'users#create'

end
Update the sessions_controller with the logic to log users in and out.

  # app/controllers/sessions_controller.rb

  def create
    user = User.find_by_email(params[:email])
    # If the user exists AND the password entered is correct.
    if user && user.authenticate(params[:password])
      # Save the user id inside the browser cookie. This is how we keep the user 
      # logged in when they navigate around our website.
      session[:user_id] = user.id
      redirect_to '/'
    else
    # If user's login doesn't work, send them back to the login form.
      redirect_to '/login'
    end
  end

  def destroy
    session[:user_id] = nil
    redirect_to '/login'
  end
Update the application controller with new methods to look up the user, if they're logged in, and save their user object to a variable called @current_user. The helper_method line below current_user allows us to use @current_user in our view files. Authorize is for sending someone to the login page if they aren't logged in - this is how we keep certain pages our site secure... user's have to login before seeing them.



# app/controllers/application_controller.rb

class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  end
  helper_method :current_user

  def authorize
    redirect_to '/login' unless current_user
  end

end
Add a before_filter to any controller that you want to secure. This will force user's to login before they can see the actions in this controller. I've created a gif controller below which I'm going to secure. The routes for this controller were added to the routes.rb in the beginning of this tutorial.

# app/controllers/gif_controller.rb

class GifController < ApplicationController

  before_filter :authorize

  def cool
  end

  def free
  end

end
You can update your application layout file to show the user's name if they're logged in and some contextual links.

<!-- app/views/layout/application.html.erb -->

<!DOCTYPE html>
<html>
<head>
  <title>GifVault</title>
  <%= stylesheet_link_tag    "application", media: "all", "data-turbolinks-track" => true %>
  <%= javascript_include_tag "application", "data-turbolinks-track" => true %>
  <%= csrf_meta_tags %>
</head>
<body>

# added these lines.
<% if current_user %>
  Signed in as <%= current_user.name %> | <%= link_to "Logout", '/logout' %>
<% else %>
  <%= link_to 'Login', '/login' %> | <%= link_to 'Signup', '/signup' %>
<% end %>

<%= yield %>

</body>
</html>
…………………………………………………….





for rails 4 this is different (no more attr_accessors on models), modifying this we need a attr_reader :password and a way of setting the password and password_confirmation so:

class User < ActiveRecord::Base
  attr_reader :password
  before_save :encrypt_password

  validates_confirmation_of :password
  validates_presence_of :password, :on => :create
  validates_presence_of :email
  validates_uniqueness_of :email

  def self.authenticate(email, password)
    user = find_by_email(email)
    if user && user.password_hash == BCrypt::Engine.hash_secret(password, user.password_salt)
      user
    else
      nil
    end
  end

  def encrypt_password
    if password.present?
      self.password_salt = BCrypt::Engine.generate_salt
      self.password_hash = BCrypt::Engine.hash_secret(password, password_salt)
    end
  end

  ##
  # accessor
  def password=(unencrypted_password)
    unless unencrypted_password.blank?
      @password = unencrypted_password
    end
  end

  ##
  # accessor
  def password_confirmation=(unencrypted_password)
    @password_confirmation = unencrypted_password
  end
end
However, if we look at the has_secure_password method here we see that the business logic is in the password=(unencrypted) rather than a before save callback (which makes obvious sense) I feel that that's probably the cleanest way to execute this.