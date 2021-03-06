# 國立彰化師範大學
# 選課網址: http://webap0.ncue.edu.tw/deanv2/other/ob010

module CourseCrawler::Crawlers
class NcueCourseCrawler < CourseCrawler::Base

  DAYS = {
    "一" => 1,
    "二" => 2,
    "三" => 3,
    "四" => 4,
    "五" => 5,
    "六" => 6,
    "日" => 7
  }.freeze

  PERIODS = CoursePeriod.find('NCUE').code_map

  def initialize  year: nil, term: nil, update_progress: nil, after_each: nil # initialize 94建構子
    @year = year || current_year
    @term = term || current_term
    @query_url = "http://webap0.ncue.edu.tw/deanv2/other/ob010"
    # @ic = Iconv.new('utf-8//translit//IGNORE', 'big-5')
    #@result_url = "https://web085003.adm.ncyu.edu.tw/pub_depta2.aspx"
    # 這邊是因為嘉義大學的結果是另一個網頁
    @post_url = "http://webap0.ncue.edu.tw/DEANV2/Other/OB010"

    @after_each_proc = after_each
    @update_progress_proc = update_progress
  end

  def courses
    @courses = []

    puts "get url ..."

    # start write your crawler here:
    r = RestClient.get @query_url
    doc = Nokogiri::HTML(r)

    post_dept_values = doc.css('select[name="sel_cls_id"] option').map { |opt| opt[:value] }[1..-1]
    dept_names = doc.css('select[name="sel_cls_id"] option').map(&:text)[1..-1] # 也要存資料用的，也可以當辨識

    post_dept_values.each_with_index do |dept_value, index|
      set_progress "#{index+1} / #{post_dept_values.count}\n"

      r = RestClient::Request.execute(method: :post,
                                      url: @post_url,
                                      timeout: 600,
                                      payload: {
                                        "sel_cls_branch" => "D",
                                        "sel_yms_year" => @year - 1911,
                                        "sel_yms_smester" => @term,
                                        "sel_cls_id" => dept_value,
                                        "X-Requested-With" => "XMLHttpRequest"
                                      })

      department = dept_names[index]
      doc = Nokogiri::HTML(r)

      doc.css('tr')[1..-1].each do |row|
        columns = row.css('td')

        course_days = []
        course_periods = []
        course_locations = []

        period_raw_data = columns[11].text.strip
        period_raw_data.match(/\((?<day>[一二三四五六日])\) (?<s>\d{2})(\-(?<e>\d{2}))? (?<loc>.+)/) do |m|

          day = DAYS[m[:day]]

          start_period = PERIODS[m[:s]]
          end_period = PERIODS[m[:e]]

          end_period = start_period if m[:e].nil?

          location = m[:loc]

          (start_period..end_period).each do |period|
            course_days << day
            course_periods << period
            course_locations << location
          end
        end

        puts "data crawled : " + columns[3].text

        course = {
          department:   columns[2].text,
          name:         columns[3].text,
          year:         @year,
          term:         @term,
          code:         "#{@year}-#{@term}-#{columns[1].text}", # #{這個裡面放變數}
          general_code: columns[1].text,
          credits:      columns[9].text,
          required:     columns[6].text.include?('必'),
          lecturer:     columns[10].text.strip,
          day_1:        course_days[0],
          day_2:        course_days[1],
          day_3:        course_days[2],
          day_4:        course_days[3],
          day_5:        course_days[4],
          day_6:        course_days[5],
          day_7:        course_days[6],
          day_8:        course_days[7],
          day_9:        course_days[8],
          period_1:     course_periods[0],
          period_2:     course_periods[1],
          period_3:     course_periods[2],
          period_4:     course_periods[3],
          period_5:     course_periods[4],
          period_6:     course_periods[5],
          period_7:     course_periods[6],
          period_8:     course_periods[7],
          period_9:     course_periods[8],
          location_1:   course_locations[0],
          location_2:   course_locations[1],
          location_3:   course_locations[2],
          location_4:   course_locations[3],
          location_5:   course_locations[4],
          location_6:   course_locations[5],
          location_7:   course_locations[6],
          location_8:   course_locations[7],
          location_9:   course_locations[8]
        }

        @after_each_proc.call(course: course) if @after_each_proc
        @courses << course
      end # end each row

      # table = doc.css('table[border="1"][align="center"][cellpadding="1"][cellspacing="0"][width="99%"]')[0]

      # rows = table.css('tr:not(:first-child)')
      # rows.each do |row|
      #   table_datas = row.css('td')

      #   course = {
      #     department_code: table_datas[2].text,
      #     # name: aaa,
      #     # code: aaa,
      #   }

      #   @courses << course
      # end
      # File.write("temp/#{dept_value}.html", r)
    end # end each dept_values

    # puts "hello"
    puts "Project finished !!!"
    @courses
  end # end courses method

  # def current_year
  #   (Time.zone.now.month.between?(1, 7) ? Time.zone.now.year - 1 : Time.zone.now.year)
  # end

  # def current_term
  #   (Time.zone.now.month.between?(2, 7) ? 2 : 1)
  # end
end
end
