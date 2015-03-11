# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)
# IMPORTANT - READ THIS TASK!
# This is the method in which you will initiate the scrape
# of the student site to populate your development database.
desc 'Scrape the student site'
task :scrape_students do
  # First, load the student scraper, it isn't really part of our environment
  # only this task needs it.
  require './lib/student_scraper'

  # Let's instantiate and call. Make sure to read through the StudentScraper class.
  scraper = StudentScraper.new('http://ruby007.students.flatironschool.com')
  scraper.call
end
Rails.application.load_tasks
