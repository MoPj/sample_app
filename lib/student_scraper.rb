require 'open-uri'

class StudentScraper
  attr_reader :main_index_url

  def initialize(main_index_url)
    @main_index_url = main_index_url
  end
  def student_page_url(student)
    "#{self.main_index_url}/#{student}"
  end

  def parse_student_pages(students_array)
    students_array.collect do |student|
      student_page = Nokogiri::HTML(open(student_page_url(student)))
      name = student_page.css('h4.ib_main_header').text

      # This is using the find_or_create method defined by Sequel
      # http://sequel.rubyforge.org/rdoc/classes/Sequel/Model/ClassMethods.html#method-i-find_or_create
      user = User.find_or_create_by(:name => name)
             user.email = "projectflatironemail.gmail.com"
             user.password = "flatiron"
             user.password_confirmation = "flatiron"
             user.activated = true
             user.activated_at = Time.zone.now
             user.profile_image = parse_profile_image(student_page)
             user.background_image = parse_background_image(student_page)


      puts "Saving user ##{user.id} (#{user.name})..." if user.save
      user
   end
  end

  def parse_profile_image(student_page)
    student_page.css('.top-page-title div img')[0].attributes["src"].value
  end

  def parse_background_image(student_page)
    student_page.css('style')[0].children[0].to_s[/\((.*?)\)/][1...-1]
  end

  def call
    index_page = Nokogiri::HTML(open("#{self.main_index_url}"))
    students_array = get_student_links(index_page)
    students = parse_student_pages(students_array)
  end

  def get_student_links(index_page)
    index_page.css('li.home-blog-post div.blog-thumb a').collect do |link|
      link.attr('href')
    end
  end
end


  # Let's instantiate and call. Make sure to read through the StudentScraper class.
  scraper = StudentScraper.new('http://ruby007.students.flatironschool.com')
  scraper.call


# Users     projectflatironemail.gmail.com  flatiron
User.create!(name:  "Sample User",
             email: "projectflatironemail.gmail.com",
             password:              "flatiron",
             password_confirmation: "flatiron",
             admin:     true,
             activated: true,
             activated_at: Time.zone.now)

# 99.times do |n|
#   name  = Faker::Name.name
#   email = "example-#{n+1}@sample.com"
#   password = "password"
#   User.create!(name: name,
#               email: email,
#               password:              password,
#               password_confirmation: password,
#               activated: true,
#               activated_at: Time.zone.now)
# end

# Microposts
users = User.order(:created_at).take(6)
50.times do
  content = Faker::Lorem.sentence(5)
  users.each { |user| user.microposts.create!(content: content) }
end

# Following relationships
users = User.all
user  = users.first
following = users[2..50]
followers = users[3..40]
following.each { |followed| user.follow(followed) }
followers.each { |follower| follower.follow(user) }