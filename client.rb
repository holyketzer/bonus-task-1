require 'openssl'
require 'faraday'

OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

# Есть три типа эндпоинтов API
# Тип A:
#   - работает 1 секунду
#   - одновременно можно запускать не более трёх
# Тип B:
#   - работает 2 секунды
#   - одновременно можно запускать не более двух
# Тип C:
#   - работает 1 секунду
#   - одновременно можно запускать не более одного
#
def a(value)
  puts "Get A for #{value}"
  Faraday.get("https://localhost:9292/a?value=#{value}").body
end

def b(value)
  puts "Get B for #{value}"
  Faraday.get("https://localhost:9292/b?value=#{value}").body
end

def c(value)
  puts "Get C for #{value}"
  Faraday.get("https://localhost:9292/c?value=#{value}").body
end

# Референсное решение, приведённое ниже работает правильно, занимает ~19.5 секунд
# Надо сделать в пределах 7 секунд

def collect_sorted(arr)
  arr.sort.join('-')
end

a1 = [11, 12, 13].map do |v|
  Thread.new { a(v) }
end

b1 = Thread.new { b(1) }
b2 = Thread.new { b(2) }

a1.each(&:join)

a2 = [21, 22, 23].map do |v|
  Thread.new { a(v) }
end

a2.each(&:join)

a3 = [31, 32, 33].map do |v|
  Thread.new { a(v) }
end

b1.join
b2.join

b3 = Thread.new { b(3) }

c1 = Thread.new do
  ab1 = "#{collect_sorted(a1.map(&:value))}-#{b1.value}"
  c(ab1)
end

a3.each(&:join)

c1.join

c2 = Thread.new do
  ab2 = "#{collect_sorted(a2.map(&:value))}-#{b2.value}"
  c(ab2)
end

b3.join
c2.join

c3 = Thread.new do
  ab3 = "#{collect_sorted(a3.map(&:value))}-#{b3.value}"
  c(ab3)
end

c3.join

c123 = collect_sorted([c1.value, c2.value, c3.value])
result = a(c123)
puts "RESULT = #{result}"

if result != '0bbe9ecf251ef4131dd43e1600742cfb'
  puts 'Error!'
end
