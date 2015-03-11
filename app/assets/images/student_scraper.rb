# This may or may not work. Feel free to replace with your own.
require 'open-uri'

class StudentScraper
  attr_reader :main_index_url

  def initialize(main_index_url)
    @main_index_url = main_index_url
  end

  def value_missing
    "Coming Soon..."
  end

  def student_page_url(student)
    "#{self.main_index_url}/#{student}"
  end

  def parse_work_title(student_page)
    begin
      student_page.css("div.services p")[1].children[1].text
    rescue
      value_missing
    end
  end

  def parse_personal_project(student_page)
    begin
      student_page.css('h3:contains("Personal Projects")')[0].parent.parent.children[-2].text
    rescue
      value_missing
    end
  end

  def parse_social_media(student_page)
    student_page.css('div.social-icons a').collect do |link|
      link.attr('href')
    end
  end

  def parse_profile_image(student_page)
    student_page.css('.top-page-title div img')[0].attributes["src"].value
  end

  def parse_background_image(student_page)
    student_page.css('style')[0].children[0].to_s[/\((.*?)\)/][1...-1]
  end

  def parse_quote(student_page)
    student_page.css('div.textwidget h3').text
  end

  def parse_bio(student_page)
    student_page.css('div.services p').collect do |link|
      link.content.strip if link.element_children.empty?
    end.compact[0]
  end

  def parse_education(student_page)
    student_page.css('div.services ul li').collect do |link|
      link.content
    end.join(",")
  end

  def parse_student_pages(students_array)
    students_array.collect do |student|
      student_page = Nokogiri::HTML(open(student_page_url(student)))
      name = student_page.css('h4.ib_main_header').text

      # This is using the find_or_create method defined by Sequel
      # http://sequel.rubyforge.org/rdoc/classes/Sequel/Model/ClassMethods.html#method-i-find_or_create
      student = Student.find_or_create_by(:name => name)

      student.profile_image = parse_profile_image(student_page)
      student.background_image = parse_background_image(student_page)

      social_media  = parse_social_media(student_page)
      student.twitter = social_media[0]
      student.linkedin = social_media[1]
      student.github = social_media[2]

      student.quote = parse_quote(student_page)
      student.bio = parse_bio(student_page)
      student.work = value_missing
      student.work_title = parse_work_title(student_page)
      student.education = parse_education(student_page)

      puts "Saving student ##{student.id} (#{student.name})..." if student.save
      student
   end
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
