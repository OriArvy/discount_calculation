# frozen_string_literal: true

require 'date'

find_modified_txt_files = Dir['lib/*txt'].sort_by { |file_name| File.stat(file_name).mtime }
newest_file = find_modified_txt_files.last

file = File.open(newest_file.to_s)
file_data = file.read
structured_file_data = file_data.split("\n")

structured_transactions_array = structured_file_data.map do |transaction|
  { 'Date' => transaction.split(' ')[0], 'PackageSize' => transaction.split(' ')[1], 'Provider' => transaction.split(' ')[2] }
end

def set_price(items)
  items.each do |item|
    case
    when item['Provider'] == 'MR' && item['PackageSize'] == 'S'
      item['Price'] = 2.00
    when item['Provider'] == 'MR' && item['PackageSize'] == 'M'
      item['Price'] = 3.00
    when item['Provider'] == 'MR' && item['PackageSize'] == 'L'
      item['Price'] = 4.00
    when item['Provider'] == 'LP' && item['PackageSize'] == 'S'
      item['Price'] = 1.50
    when item['Provider'] == 'LP' && item['PackageSize'] == 'M'
      item['Price'] = 4.90
    when item['Provider'] == 'LP' && item['PackageSize'] == 'L'
      item['Price'] = 6.90
    else
      item['Price'] = 'IGNORED!'
    end
  end
end

def add_discount_field(items)
  items.each do |item|
    item['Discount'] = '-'
  end
end

def add_final_price_field(items)
  items.each do |item|
    item['FinalPrice'] = item['Price']
  end
end

def find_all_small_packages(items)
  small_items_array = []
  items.each do |item|
    item['PackageSize'] == 'S' ? small_items_array << item : ''
  end
  small_items_array
end

def find_lowest_price_of_small_packages(items)
  price_array = []
  find_all_small_packages(items).each do |item|
    item['Price'] != 'IGNORED!' ? price_array << item['Price'] : ''
  end
  price_array.min
end

def set_lowest_price_to_small_packages(items)
  find_all_small_packages(items).each do |item|
    set_discount(items) # Setting discount here does not set the final price of items that do not qualify for discounts
    if discount_applicable?(item) && item['Price'] != 'IGNORED!'
      item['FinalPrice'] = find_lowest_price_of_small_packages(items)
    end
  end
end

def set_discount(items)
  items.each do |item|
    if item['Price'] != item['FinalPrice'] && item['Price'] != 'IGNORED!'
      discount_applicable?(item) ? item['Discount'] = item['Price'] - item['FinalPrice'] : ''
      item['Discount'] = item['Price'] - item['FinalPrice']
    end
  end
end

def find_all_large_packages_by_lp(items)
  large_packages_by_lp = []
  items.each do |item|
    item['PackageSize'] == 'L' && item['Provider'] == 'LP' ? large_packages_by_lp << item : ''
  end
  large_packages_by_lp
end

# Monthly calculations were by far the most confusing part of this task, so the solution is far from optimal :(
# I am not proud of this and I am sure there is a lot to improve here, but this was the best I could think of.
def large_lp_package_discount(items)
  counter = 1
  all_large_lp_packages = find_all_large_packages_by_lp(items)
  all_large_lp_packages.each_with_index do |item, index|
    # Checking number of large items in a month
    if DateTime.parse(item['Date']).month == DateTime.parse(all_large_lp_packages[index - 1]['Date']).month
      counter += 1
      # Don't care about the actual count, just care if its 3 and if it is then apply the discount.
      counter == 3 ? item['FinalPrice'] = 0.00 : ''
    else
      counter = 1 # Resetting counter if it is a new month
    end
  end
end

def error_if_format_incorrect(items)
  items.each do |item|
    if item['Price'] == 'IGNORED!' || valid_date?(item['Date']) == false
      item['Price'] = 'IGNORED!'
      item['Discount'] = 'IGNORED!'
      item['FinalPrice'] = 'IGNORED!'
    end
  end
end

def discount_applicable?(item)
  item['TotalDiscount'].to_f <= 10
end

def valid_date?(date)
  date_format = '%Y-%m-%d'
  DateTime.strptime(date, date_format)
  true
rescue ArgumentError
  false
end

def calculate_total_discount(items)
  counter = 0
  items.each_with_index do |item, index|
    if DateTime.parse(item['Date']).month == DateTime.parse(items[index - 1]['Date']).month && (item['Discount'] != '-' && item['Discount'] != 'IGNORED!')
      counter += item['Discount'].to_f
      item['TotalDiscount'] = counter
    elsif item['Discount'] != '-' && item['Discount'] != 'IGNORED!'
      counter = 0
      counter = item['Discount'].to_f
      item['TotalDiscount'] = counter
    end
  end
end

# Another method that is sketchy and written pretty poorly :(
# Would love some feedback on how to improve this one
def round_down_to_monthly_discount_limit(items)
  over_limit = 0
  discounted_array = []
  items.each do |item|
    if item['TotalDiscount'].to_f >= 10
      over_limit = item['TotalDiscount'] - 10
      discounted_array << item
    end
  end
  discounted_array.each_with_index do |item, index|
    if item['Price'] == 6.9
      item['Discount'] -= item['TotalDiscount'] - 10
      item['FinalPrice'] = item['Price'].floor(2) - item['Discount'].floor(2)
      item['FinalPrice'].floor(2)
      over_limit = 0
    else
      item['Discount'] -= over_limit.floor(2)
      item['Discount'] = item['Discount'].ceil(2)
      item['FinalPrice'] = item['Price'] - item['Discount']
      over_limit = 0.5
    end
  end
end

def structured_response(items)
  array = []
  items.each do |item|
    if item['FinalPrice'] != 'IGNORED!'
      array << "#{item['Date']} #{item['PackageSize']} #{item['Provider']} #{item['FinalPrice'].floor(2)} #{item['Discount']}"
    else
      array << "#{item['Date']} #{item['PackageSize']} #{item['Provider']} #{item['FinalPrice']} #{item['Discount']}"
    end
  end
  array
end

set_price(structured_transactions_array)
add_discount_field(structured_transactions_array)
add_final_price_field(structured_transactions_array)
find_lowest_price_of_small_packages(structured_transactions_array)
large_lp_package_discount(structured_transactions_array)
error_if_format_incorrect(structured_transactions_array)
set_lowest_price_to_small_packages(structured_transactions_array)
set_discount(structured_transactions_array)
calculate_total_discount(structured_transactions_array)
round_down_to_monthly_discount_limit(structured_transactions_array)

puts structured_response(structured_transactions_array)
