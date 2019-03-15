require 'openssl'
require 'faraday'
require 'concurrent-ruby'

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
POOL_A = Concurrent::FixedThreadPool.new(3)
POOL_B = Concurrent::FixedThreadPool.new(2)
POOL_C = Concurrent::FixedThreadPool.new(1)

def a(value)
  Concurrent::Promises.future_on(POOL_A) do
    puts "Get A for #{value}"
    Faraday.get("https://localhost:9292/a?value=#{value}").body
  end
end

def b(value)
  Concurrent::Promises.future_on(POOL_B) do
    puts "Get B for #{value}"
    Faraday.get("https://localhost:9292/b?value=#{value}").body
  end
end

def c(value)
  Concurrent::Promises.future_on(POOL_C) do
    puts "Get C for #{value}"
    Faraday.get("https://localhost:9292/c?value=#{value}").body
  end
end

def ab(aa_feature, b_feature)
  Concurrent::Promises.zip(b_feature, *aa_feature).then do |b, *aa|
    c("#{collect_sorted(aa)}-#{b}")
  end.flat
end

# Референсное решение, приведённое ниже работает правильно, занимает ~19.5 секунд
# Надо сделать в пределах 7 секунд

def collect_sorted(arr)
  arr.sort.join('-')
end

aa1 = [11, 12, 13].map { |v| a(v) }
aa2 = [21, 22, 23].map { |v| a(v) }
aa3 = [31, 32, 33].map { |v| a(v) }

b1 = b(1)
b2 = b(2)
b3 = b(3)

c1 = ab(aa1, b1)
c2 = ab(aa2, b2)
c3 = ab(aa3, b3)

c123 = Concurrent::Promises.zip(c1, c2, c3).then do |*cc|
  a(collect_sorted(cc))
end.flat

puts 'Go!'

result = c123.value!

puts "\nRESULT = #{result}"

if result != '0bbe9ecf251ef4131dd43e1600742cfb'
  raise 'Error!'
end
