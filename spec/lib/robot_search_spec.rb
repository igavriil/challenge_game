require 'spec_helper'
require_relative '../../lib/robot_search'

describe PameDiakopes::Robot do
	before(:each) do
	  PameDiakopes::Robot.send(:public, *PameDiakopes::Robot.private_instance_methods)  
	end

	it "has initialize empty path" do
		expect(subject.path).to be_empty
	end

	it "has no knowledge" do
		expect(subject.knowledge).to be_empty
	end

	it "circles positions" do
		map = PameDiakopes::Map.new("maps/empty_3_3.txt")
		start = PameDiakopes::Point.new(1, 1)
		robot = subject
		robot.place(map, start)
		expect{ subject.search }.to change{ subject.path.length}.from(0).to(8)
	end

	it "learns all the map" do
		map = PameDiakopes::Map.new("maps/empty_3_8.txt")
		start = PameDiakopes::Point.new(1, 1)
		robot = subject
		robot.place(map, start)
		expect{ subject.search }.to change{ subject.knowledge.length}.from(0).to(46)
	end

	it "marks all posible closed positions" do
		map = PameDiakopes::Map.new("maps/empty_3_8.txt")
		start = PameDiakopes::Point.new(1, 1)
		robot = subject
		robot.place(map, start)
		expect{ subject.search }.to change{ subject.closed_positions.length}.from(0).to(24)
	end

	it "finds the best path" do
		map = PameDiakopes::Map.new("maps/a_star.txt")
		start = PameDiakopes::Point.new(1, 1)
		robot = subject
		robot.place(map, start)
		robot.search
		from = PameDiakopes::Point.new(3, 3)
		to = PameDiakopes::Point.new(3, 10)
		path = robot.move_to(from, to)
		expect(path).to include(to)
		expect(path).not_to include(from)
		expect(path.length).to be(15)
	end
end
