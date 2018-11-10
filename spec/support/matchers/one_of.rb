# a simple matcher for matching one value of an array
RSpec::Matchers.define :one_of do |x|
  match { |actual| x.include?(actual) }
end
