local data = string.split(line, ", ")

-- fix last name that ends with a dot
data[#data] = string.sub(data[#data], 1, #data[#data] - 1)

-- fix the 'and Name' from qw2
if data[#data]:starts("and ") then
  data[#data] = data[#data]:match("and (%w+)")
end

for _, name in ipairs(data) do
  EnemyCity(name, enemycity)
end