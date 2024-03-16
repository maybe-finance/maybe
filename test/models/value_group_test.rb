require "test_helper"

class ValueGroupTest < ActiveSupport::TestCase
    setup do
        checking = accounts(:checking)
        savings = accounts(:savings_with_valuation_overrides)
        collectable = accounts(:collectable)

        # Level 1
        @assets = ValueGroup.new("Assets")

        # Level 2
        @depositories = @assets.add_child_node("Depositories")
        @other_assets = @assets.add_child_node("Other Assets")

        # Level 3 (leaf/value nodes)
        @checking_node = @depositories.add_value_node(checking)
        @savings_node = @depositories.add_value_node(savings)
        @collectable_node = @other_assets.add_value_node(collectable)
    end

    test "empty group works" do
        group = ValueGroup.new

        assert_equal "Root", group.name
        assert_equal [], group.children
        assert_equal 0, group.sum
        assert_equal 0, group.avg
        assert_equal 100, group.percent_of_total
        assert_nil group.parent
    end

    test "group without value nodes has no value" do
        assets = ValueGroup.new("Assets")
        depositories = assets.add_child_node("Depositories")

        assert_equal 0, assets.sum
        assert_equal 0, depositories.sum
    end

    test "sum equals value at leaf level" do
        assert_equal @checking_node.value, @checking_node.sum
        assert_equal @savings_node.value, @savings_node.sum
        assert_equal @collectable_node.value, @collectable_node.sum
    end

    test "value is nil at rollup levels" do
        assert_not_equal @depositories.value, @depositories.sum
        assert_nil @depositories.value
        assert_nil @other_assets.value
    end

    test "generates list of value nodes regardless of level in hierarchy" do
        assert_equal [ @checking_node, @savings_node, @collectable_node ], @assets.value_nodes
        assert_equal [ @checking_node, @savings_node ], @depositories.value_nodes
        assert_equal [ @collectable_node ], @other_assets.value_nodes
    end

    test "group with value nodes aggregates totals correctly" do
        assert_equal 5000, @checking_node.sum
        assert_equal 20000, @savings_node.sum
        assert_equal 550, @collectable_node.sum

        assert_equal 25000, @depositories.sum
        assert_equal 550, @other_assets.sum

        assert_equal 25550, @assets.sum
    end

    test "group averages leaf nodes" do
        assert_equal 5000, @checking_node.avg
        assert_equal 20000, @savings_node.avg
        assert_equal 550, @collectable_node.avg

        assert_in_delta 12500, @depositories.avg, 0.01
        assert_in_delta 550, @other_assets.avg, 0.01
        assert_in_delta 8516.67, @assets.avg, 0.01
    end

    # Percentage of parent group (i.e. collectable is 100% of "Other Assets" group)
    test "group calculates percent of parent total" do
        assert_equal 100, @assets.percent_of_total
        assert_in_delta 97.85, @depositories.percent_of_total, 0.1
        assert_in_delta 2.15, @other_assets.percent_of_total, 0.1
        assert_in_delta 80.0, @savings_node.percent_of_total, 0.1
        assert_in_delta 20.0, @checking_node.percent_of_total, 0.1
        assert_equal 100, @collectable_node.percent_of_total
    end

    test "handles unbalanced tree" do
        vehicles = @assets.add_child_node("Vehicles")

        # Since we didn't add any value nodes to vehicles, shouldn't affect rollups
        assert_equal 25550, @assets.sum
        assert_nil @assets.series
    end


    test "can attach and aggregate time series" do
        checking_series = TimeSeries.new([ { date: 1.day.ago, amount: 4000 }, { date: Date.current, amount: 5000 } ])
        savings_series = TimeSeries.new([ { date: 1.day.ago, amount: 19000 }, { date: Date.current, amount: 20000 } ])

        @checking_node.attach_series(checking_series)
        @savings_node.attach_series(savings_series)

        assert_not_nil @checking_node.series
        assert_not_nil @savings_node.series

        assert_equal @checking_node.sum, @checking_node.series.last.value
        assert_equal @savings_node.sum, @savings_node.series.last.value

        aggregated_depository_series = TimeSeries.new([ { date: 1.day.ago, amount: 23000 }, { date: Date.current, amount: 25000 } ])
        aggregated_assets_series = TimeSeries.new([ { date: 1.day.ago, amount: 23000 }, { date: Date.current, amount: 25000 } ])

        assert_equal aggregated_depository_series.values, @depositories.series.values
        assert_equal aggregated_assets_series.values, @assets.series.values
    end

    test "attached series last value must equal value node value" do
        assert_equal 5000, @checking_node.value
        assert_raises(RuntimeError) do
            @checking_node.attach_series(TimeSeries.new([ { date: Date.current, amount: 6000 } ]))
        end
    end

    test "attached series must be a TimeSeries" do
        assert_raises(RuntimeError) do
            @checking_node.attach_series([])
        end
    end

    test "cannot add time series to non-leaf node" do
        assert_raises(RuntimeError) do
            @assets.attach_series(TimeSeries.new([]))
        end
    end

    test "can only add value node at leaf level of tree" do
        root = ValueGroup.new("Root Level")
        grandparent = root.add_child_node("Grandparent")
        parent = grandparent.add_child_node("Parent")

        value_node = parent.add_value_node(OpenStruct.new({ name: "Value Node", value: 100 }))

        assert_raises(RuntimeError) do
            value_node.add_value_node(OpenStruct.new({ name: "Value Node", value: 100 }))
        end

        assert_raises(RuntimeError) do
            grandparent.add_value_node(OpenStruct.new({ name: "Value Node", value: 100 }))
        end
    end
end
