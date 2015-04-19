require_relative '../lib/robot_search'

map = PameDiakopes::Map.new("maps/pd_example.txt")
target = PameDiakopes::Point.new(6, 6)
map.set_target(target)

start = PameDiakopes::Point.new(2, 2)
r = PameDiakopes::Robot.new
r.place(map, start)	
path = r.search

map.animate_path(path)
path.each_with_index {|position, step| puts "#{step} => #{position}" }