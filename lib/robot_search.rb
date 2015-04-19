module PameDiakopes

  class Queue
    def initialize
      @elements = []
    end

    def dequeue
      if empty?
        return nil
      else
        return @elements.pop
      end
    end

    def enqueue_front(element)
      @elements.push(element)
    end

    def empty?
      return @elements.empty?
    end
  end

  class Point
    attr_reader :x, :y

    def initialize(x,y)
      @x, @y = x, y
    end

    def +(other)
      raise TypeError, "Point-like argument expected" unless
          other.respond_to? :x and other.respond_to? :y
      return Point.new(@x + other.x, @y + other.y)
    end

    def is_neighbour?(other)
      if other.is_a? Point
        return (@x - other.x).abs + (@y - other.y).abs == 1
      else
        return false
      end
    end

    def -@
      return Point.new(-@x, -@y)
    end

    def eq?(other)
      if other.is_a? Point
        return @x==other.x && @y==other.y
      else
        return false
      end
    end

    def to_s
      return "x#{@x}_y#{@y}"
    end

    def to_sym
      return self.to_s.to_sym
    end
  end

  class PriorityQueue
    def initialize
      @elements = Hash.new { |hash, key| hash[key] = [] }
    end

    def enqueue(element, priority)
      @elements[priority].push(element)
    end

    def dequeue
      return nil if @elements.empty?
      element, priority = *@elements.min
      output = priority.shift
      @elements.delete(element) if priority.empty?
      return output
    end

    def empty?
      return @elements.empty?
    end
  end

  class Map
    TARGET = 2
    WALL = 1
    ALL_NEIGHBOURS = 4

    UNIT_X = Point.new(1, 0)
    UNIT_Y = Point.new(0, 1)

    def initialize(file_path)
      @map = []
      @height = 0
      @width = 0
      file_to_map(file_path)
    end

    # add walls to borders
    def file_to_map(file_path)
       File.open(File.expand_path(file_path)) do |f|
        f.each_line do |line|
          row = line.split.map(&:to_i)
          row.push(1)
          row.insert(0, 1)
          @map.push(row)
          @height += 1
          @width = row.length
        end
      end

      horizontal_border = Array.new(@width, 1)
      @map.insert(0, horizontal_border)
      @map.push(horizontal_border)
      @height += 2
    end

    def [](position)
      x, y = translate_coordinates(position.x, position.y)
      if !x.nil? and !y.nil?
        return @map[x][y]
      end
    end

    def translate_coordinates(x, y)
      x = (x - @height + 1).abs
      y = y
      if x.between?(0, @height - 1) and y.between?(0, @width - 1)
        return [x, y]
      end
    end

    def set_target(position)
      x, y = translate_coordinates(position.x, position.y)
      @map[x][y] = TARGET
    end

    def set_position(position, value)
      x, y = translate_coordinates(position.x, position.y)
      @map[x][y] = value
    end

    def current_position(position)
      x, y = translate_coordinates(position.x, position.y)
      @map[x][y] = '*'
    end

    def display_map
      system "clear" or system "cls"
      @map.each do |row|
        row.each do |column|
          print " #{column}"
        end
        puts
      end
    end

    def animate_path(path)
      path.each do |position|
        self.set_position(position, '*')
        display_map
        self.set_position(position, 0)
        sleep(0.4)
      end  
    end

    def neighbours(position)
      up = position + UNIT_X
      down = position + (-UNIT_X)
      right = position + UNIT_Y
      left = position + (-UNIT_Y)

      all_neighbours = {up => self[up], down => self[down], right => self[right], left => self[left]}
      return all_neighbours.delete_if { |k, v| v.nil? }
    end

    def is_target?(position)
      return self[position] == TARGET
    end
  end

  class Robot
    attr_reader :candidate_positions, :path, :knowledge, :closed_positions, :visited_positions

    STEP_COST = 1

    def initialize
      @candidate_positions = Queue.new
      @seen_positions = Hash.new(0)
      @visited_positions = Hash.new(0)
      @closed_positions = Hash.new(0)
      @knowledge = {}
      @path = []
    end

    def place(map, position)
      @map = map
      add_candidate(position)
    end

    # dfs algorithm
    def search
      while !@candidate_positions.empty?
        position = get_candidate

        if position.nil?
          puts "i can't find the target"
          return @path
        end
        
        move_to(@path.last, position)
        update_visited(position)

        ordered_neighbours(position).each do |neighbour, value|
          update_knowledge(neighbour, value)
          update_seen(neighbour)

          if @map.is_target?(neighbour)
            move_to(@path.last, neighbour)
            puts "i found the target" 
            return @path
          end

          unless (is_visited?(neighbour) or is_wall?(neighbour) or is_closed?(neighbour))
            add_candidate(neighbour)
          end
        end
      end
      puts "i can't find the target"
      return @path
    end

    private 

    def get_candidate
      candidate = NIL
      loop do
        candidate = @candidate_positions.dequeue
        if candidate.nil?
          break
        else
          break unless is_closed?(candidate) 
        end
      end
      return candidate
    end

    def update_visited(position)
      @visited_positions[position.to_sym] += 1
      update_seen(position)
    end

    # reverse sorting with least viewed position at last
    # prioritise aame direction
    # introduce randomness at ties
    # inserted in reverse order on the candidate list
    def ordered_neighbours(position)
      neighbours = @map.neighbours(position)
      seen_count = []

      neighbours.each_key do |neighbour|
        if (position + (-neighbour)).eq?(direction) and @seen_positions[neighbour.to_sym] == 0
          seen_count.push(-1)
        else
          seen_count.push(@seen_positions[neighbour.to_sym])
        end
      end

      ordered = neighbours.sort_by.each_with_index{|el,i| [seen_count[i], rand]}.to_h
      return ordered.to_a.reverse.to_h
    end

    def direction
      if !@path[-2].nil?
        return @path[-2] + (-@path[-1])
      else
        return Point.new(0, 0)
      end
    end

    def update_knowledge(position, value)
      @knowledge[position.to_sym] = value
    end

    def update_seen(position)
      @seen_positions[position.to_sym] += 1

      @map.neighbours(position).each_key do |neighbour|
        if all_neighbours_seen?(neighbour)
          update_closed(neighbour)
        end
      end
    end

    def all_neighbours_seen?(position)
      neighbours_seen = 0

      @map.neighbours(position).each_key do |neighbour|
        if is_seen?(neighbour)
          neighbours_seen += 1
        end
      end
      return neighbours_seen == Map::ALL_NEIGHBOURS
    end

    def update_closed(position)
      @closed_positions[position.to_sym] = 1
    end

    def is_visited?(position)
      return @visited_positions.key?(position.to_sym)
    end

    def is_seen?(position)
      return @seen_positions.key?(position.to_sym)
    end

    def is_closed?(position)
      return @closed_positions.key?(position.to_sym)
    end

    def is_wall?(position)
      return @knowledge[position.to_sym] == Map::WALL
    end

    def add_candidate(position)
      @candidate_positions.enqueue_front(position)
    end

    # move strategy
    # if the point not neighbouring then move with A*
    # use manhattan heuristic
    def move_to(start, goal)
      if start.nil? or start.is_neighbour?(goal)
        @path.push(goal)
      else
        frontier = PriorityQueue.new
        frontier.enqueue(start, 0)
        came_from = {}
        cost_so_far = {}
        came_from[start.to_sym] = NIL
        cost_so_far[start.to_sym] = 0

        while !frontier.empty?
          current = frontier.dequeue

          if current.eq?(goal)
            shortest_path = reconstuct_path(start, goal, came_from)
            shortest_path.each { |position| update_seen(position)}
            @path.push(*shortest_path)
            return shortest_path
          end

          seen_neighboors(current).each do |neighbour, value|
            unless is_wall?(neighbour)
              new_cost = cost_so_far[current.to_sym] + STEP_COST

              if ((cost_so_far.key?(neighbour.to_sym) and new_cost < cost_so_far[neighbour.to_sym]) or !cost_so_far.key?(neighbour.to_sym))
                cost_so_far[neighbour.to_sym] = new_cost
                priority = new_cost + heuristic(goal, neighbour)
                frontier.enqueue(neighbour, priority)
                came_from[neighbour.to_sym] = current
              end
            end
          end
        end
      end
    end

    def seen_neighboors(position)
      all_neighbours = {}
      up = position + Map::UNIT_X
      down = position + (-Map::UNIT_X)
      right = position + Map::UNIT_Y
      left = position + (-Map::UNIT_Y)

      [up, down, left, right].each do |neighbour|
        all_neighbours[neighbour] = @knowledge[neighbour.to_sym] if @knowledge.key?(neighbour.to_sym)
      end
      return all_neighbours
    end

    # Manhattan Heuristic for A*
    def heuristic(a, b)
      return (a.x - b.x).abs + (a.y - b.y).abs
    end

    # Reversing A* to get shortest path
    def reconstuct_path(start, goal, came_from)
      current = goal
      path = [current]
      while !current.eq?(start)
        current = came_from[current.to_sym]
        path.push(current)
      end
      path = path.reverse.drop(1)
      return path
    end
  end
end