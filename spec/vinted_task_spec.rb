# frozen_string_literal: true

require_relative '../lib/vinted_task'

RSpec.describe 'vinted_task' do
  response = [
    { 'Date' => '2015-02-05', 'PackageSize' => 'L', 'Provider' => 'LP' },
    { 'Date' => '2015-02-06', 'PackageSize' => 'M', 'Provider' => 'MR' },
    { 'Date' => '2015-02-07', 'PackageSize' => 'S', 'Provider' => 'LP' },
    { 'Date' => '2015-02-08', 'PackageSize' => 'S', 'Provider' => 'MR' },
    { 'Date' => '2015-02-09', 'PackageSize' => 'L', 'Provider' => 'LP' },
    { 'Date' => '2015-02-10', 'PackageSize' => 'L', 'Provider' => 'LP' },
    { 'Date' => '2015-02-11', 'PackageSize' => 'LG', 'Provider' => 'CUSP' },
    { 'Date' => '2015-03-10', 'PackageSize' => 'L', 'Provider' => 'LP' },

    # Adding more items in order to exceed monthly discount limit

    { 'Date' => '2015-02-08', 'PackageSize' => 'S', 'Provider' => 'MR' },
    { 'Date' => '2015-02-08', 'PackageSize' => 'S', 'Provider' => 'MR' },
    { 'Date' => '2015-02-08', 'PackageSize' => 'S', 'Provider' => 'MR' },
    { 'Date' => '2015-02-08', 'PackageSize' => 'S', 'Provider' => 'MR' },
    { 'Date' => '2015-02-08', 'PackageSize' => 'S', 'Provider' => 'MR' },
    { 'Date' => '2015-02-08', 'PackageSize' => 'S', 'Provider' => 'MR' },
    { 'Date' => '2015-02-08', 'PackageSize' => 'S', 'Provider' => 'MR' }

  ]

  it 'should set a Price for transaction' do
    set_price(response)
    expect(response[0]['Price']).to eq(6.9)
    expect(response[1]['Price']).to eq(3)
  end

  it 'should add a Discount field for transaction' do
    add_discount_field(response)
    expect(response[0]['Discount']).to eq('-')
    expect(response[1]['Discount']).to_not be_empty
  end

  it 'should add a FinalPrice field for transaction' do
    add_final_price_field(response)
    expect(response[0]['FinalPrice']).to eq(6.9)
    expect(response[1]['FinalPrice']).to be_an_instance_of(Float)
  end

  it 'should find lowest price of small packages' do
    lowest_price = find_lowest_price_of_small_packages(response)
    expect(lowest_price).to eq(1.5)
  end

  it 'should set the price of small packages to lowest price' do
    set_lowest_price_to_small_packages(response)
    expect(response[2]['FinalPrice']).to eq(1.5)
    expect(response[3]['FinalPrice']).to eq(1.5)
  end

  it 'should apply a discount for three large LP packages' do
    large_lp_package_discount(response)
    expect(response[5]['FinalPrice']).to eq(0.00)
  end

  it 'should set discount for items' do
    set_discount(response)
    expect(response[3]['Discount']).to eq(0.5)
    expect(response[5]['Discount']).to eq(6.9)
  end

  it 'should set price to IGNORED if format is incorrect' do
    error_if_format_incorrect(response)
    expect(response[6]['Price']).to eq('IGNORED!')
  end

  # it 'should apply partial discount if discount exeeds monthly limit' do
  #   round_down_to_monthly_discount_limit(response)
  #   expect(response.last['FinalPrice']).to eq(1.9)
  # end
end
