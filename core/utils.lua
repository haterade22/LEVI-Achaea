--- LEVI Utility Functions
-- Common utility functions used across modules
-- @module core.utils

local utils = {}

--- Deep copy a table
-- @param orig The table to copy
-- @return A deep copy of the table
function utils.deep_copy(orig)
  local copy
  if type(orig) == 'table' then
    copy = {}
    for orig_key, orig_value in next, orig, nil do
      copy[utils.deep_copy(orig_key)] = utils.deep_copy(orig_value)
    end
    setmetatable(copy, utils.deep_copy(getmetatable(orig)))
  else
    copy = orig
  end
  return copy
end

--- Get table size
-- @param t The table
-- @return Number of elements in the table
function utils.table_size(t)
  local count = 0
  if t then
    for _ in pairs(t) do
      count = count + 1
    end
  end
  return count
end

--- Check if table contains a value
-- @param t The table
-- @param value The value to search for
-- @return true if found, false otherwise
function utils.table_contains(t, value)
  for _, v in pairs(t) do
    if v == value then
      return true
    end
  end
  return false
end

--- Merge two tables (shallow merge)
-- @param t1 First table
-- @param t2 Second table (overrides t1)
-- @return Merged table
function utils.table_merge(t1, t2)
  local result = {}
  for k, v in pairs(t1) do
    result[k] = v
  end
  for k, v in pairs(t2) do
    result[k] = v
  end
  return result
end

--- Get timestamp in seconds
-- @return Current timestamp
function utils.timestamp()
  return os.time()
end

--- Format a timestamp as human-readable string
-- @param ts The timestamp
-- @return Formatted string
function utils.format_timestamp(ts)
  return os.date("%Y-%m-%d %H:%M:%S", ts)
end

--- Calculate time difference in seconds
-- @param start_time Start timestamp
-- @param end_time End timestamp (defaults to now)
-- @return Difference in seconds
function utils.time_diff(start_time, end_time)
  end_time = end_time or os.time()
  return end_time - start_time
end

--- Trim whitespace from string
-- @param s The string to trim
-- @return Trimmed string
function utils.trim(s)
  return s:match("^%s*(.-)%s*$")
end

--- Split string by delimiter
-- @param str The string to split
-- @param delimiter The delimiter
-- @return Array of substrings
function utils.split(str, delimiter)
  local result = {}
  local pattern = string.format("([^%s]+)", delimiter)
  for token in string.gmatch(str, pattern) do
    table.insert(result, token)
  end
  return result
end

--- Convert string to title case
-- @param str The string to convert
-- @return Title-cased string
function utils.title_case(str)
  return str:gsub("(%a)([%w_']*)", function(first, rest)
    return first:upper() .. rest:lower()
  end)
end

--- Round number to specified decimal places
-- @param num The number to round
-- @param decimals Number of decimal places
-- @return Rounded number
function utils.round(num, decimals)
  local mult = 10 ^ (decimals or 0)
  return math.floor(num * mult + 0.5) / mult
end

--- Clamp value between min and max
-- @param value The value to clamp
-- @param min Minimum value
-- @param max Maximum value
-- @return Clamped value
function utils.clamp(value, min, max)
  return math.max(min, math.min(max, value))
end

--- Log a message with severity
-- @param level Log level (DEBUG, INFO, WARN, ERROR)
-- @param message The message to log
function utils.log(level, message)
  local colors = {
    DEBUG = "<gray>",
    INFO = "<white>",
    WARN = "<yellow>",
    ERROR = "<red>"
  }
  local color = colors[level] or "<white>"
  local timestamp = os.date("%H:%M:%S")
  cecho(string.format("\n%s[%s][%s]<reset> %s", color, timestamp, level, message))
end

--- Initialize the utils module
function utils.init()
  -- Expose utils globally if needed
  if not table.size then
    table.size = utils.table_size
  end
end

return utils
