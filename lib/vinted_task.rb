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
    if discount_applicable?(items) && item['Price'] != 'IGNORED!'
      item['FinalPrice'] = find_lowest_price_of_small_packages(items)
    end
  end
end

def set_discount(items)
  items.each do |item|
    if item['Price'] != item['FinalPrice'] && item['Price'] != 'IGNORED!'
      discount_applicable?(items) ? item['Discount'] = item['Price'] - item['FinalPrice'] : ''
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

def large_lp_package_discount(items)
  find_all_large_packages_by_lp(items).count >= 3 ? find_all_large_packages_by_lp(items)[2]['FinalPrice'] = 0.0 : ''
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

def sum_of_monthly_discount(items)
  total_discount = 0
  items.each do |item|
    item['Discount'] != '-' ? total_discount += item['Discount'].to_f : ''
  end
  total_discount
end

def round_down_to_monthly_discount_limit(items)
  over_limit = 0
  discounted_array = []
  if sum_of_monthly_discount(items)
    over_limit = sum_of_monthly_discount(items) - 10
    items.each do |item|
      item['Discount'] != '-' && item['Discount'] != 'IGNORED!' ? discounted_array << item : ''
    end
  end
  discounted_array.last['Discount'] -= over_limit.floor(2)
  discounted_array.last['Discount'] = discounted_array.last['Discount'].ceil(2)
  discounted_array.last['FinalPrice'] = discounted_array.last['Price'] - discounted_array.last['Discount']
end

def discount_applicable?(items)
  sum_of_monthly_discount(items) <= 10
end

def valid_date?(date)
  date_format = '%Y-%m-%d'
  DateTime.strptime(date, date_format)
  true
rescue ArgumentError
  false
end

set_price(structured_transactions_array)
add_discount_field(structured_transactions_array)
add_final_price_field(structured_transactions_array)
find_lowest_price_of_small_packages(structured_transactions_array)
large_lp_package_discount(structured_transactions_array)
error_if_format_incorrect(structured_transactions_array)
set_lowest_price_to_small_packages(structured_transactions_array)
set_discount(structured_transactions_array)
round_down_to_monthly_discount_limit(structured_transactions_array)

puts structured_transactions_array
