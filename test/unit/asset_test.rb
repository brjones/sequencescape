require "test_helper"

class AssetTest < ActiveSupport::TestCase

  context "An asset" do
    
    context "with a barcode" do
      setup do
        @asset = Factory :asset
        @result_hash = @asset.barcode_and_created_at_hash
      end
      should "return a hash with the barcode and created_at time" do
        assert ! @result_hash.blank?
        assert @result_hash.is_a?(Hash)
        assert @result_hash[:barcode].is_a?(String)
        assert @result_hash[:created_at].is_a?(ActiveSupport::TimeWithZone)
      end
    end
    
    context "without a barcode" do
      setup do
        @asset = Factory :asset, :barcode => nil
        @result_hash = @asset.barcode_and_created_at_hash
      end
      should "return an empty hash" do
        assert @result_hash.blank?
      end
    end

    context "item that relates to an item in studies" do
      setup do
        @non_pool_item = LibraryTube.create({:name => "library tube"})
        @pool_item = MultiplexedLibraryTube.create({:name => "MX library tube"})
      end
      should "return false for #is_a_pool?" do
        assert_equal false, Asset.find(@non_pool_item.id).is_a_pool?
        assert_equal true, Asset.find(@pool_item.id).is_a_pool?
      end
    end
    
    context "#scanned_in_date" do
      setup do
        @scanned_in_asset = Factory :asset
        @unscanned_in_asset = Factory :asset
        @scanned_in_event = Factory :event, :content => Date.today.to_s, :message => "scanned in", :family => "scanned_into_lab", :eventful_type => "Asset", :eventful_id => @scanned_in_asset.id
      end
      should "return a date if it has been scanned in" do 
        assert_equal Date.today.to_s, @scanned_in_asset.scanned_in_date
      end
      
      should "return nothing if it hasn't been scanned in" do
        assert @unscanned_in_asset.scanned_in_date.blank?
      end
    end
  end

  context "Create a sample tube" do
    setup do
      @sample_tube    = Factory :sample_tube
    end
    should "be a sample tube" do
      assert @sample_tube.is_a?(SampleTube)
    end
    should "have a sample" do
      assert @sample_tube.sample.is_a?(Sample)
    end
  end

  context "create a tag instance" do
    setup do
      @tag_instance   = Factory :tag_instance
    end
    should "be a Tag Instance" do
      assert @tag_instance.is_a?(TagInstance)
    end
    should "have a tag" do
      assert @tag_instance.tag.is_a?(Tag)
    end
  end

  context "assign sample to sample tube" do
    setup do
      @sample_tube = Factory :asset, :sti_type => "SampleTube"
      @sample = Factory :sample
      @sample_tube.sample = @sample
    end
    should "correctly assign a sample to a sample tube" do
      assert @sample_tube.sample.is_a?(Sample)
      assert @sample_tube.material.is_a?(Sample)
    end

    should "not be a tag" do
      assert ! @sample_tube.sample.is_a?(Tag)
      assert ! @sample_tube.material.is_a?(Tag)
      assert_raise NoMethodError do
        @sample_tube.tag
      end
    end
  end

  context "assign tag to tag instance" do
    setup do
      @tag_instance = Factory :asset, :sti_type => "TagInstance"
      @tag_instance = @tag_instance.becomes(TagInstance)
      @tag = Factory :tag
      @tag_instance.tag = @tag
    end
    should "correctly assign a tag to a tag instance" do
      assert @tag_instance.tag.is_a?(Tag)
      assert @tag_instance.material.is_a?(Tag)
    end

    should "not be a sample" do
      assert ! @tag_instance.tag.is_a?(Sample)
      assert ! @tag_instance.material.is_a?(Sample)
      assert_raise NoMethodError do
        @tag_instance.sample
      end
    end
  end
  
  context "assign sample as a tag" do
    setup do
      @tag_instance = Factory :asset, :sti_type => "TagInstance"
      @tag_instance = @tag_instance.becomes(TagInstance)
      @sample = Factory :sample
    end
  
    should "raise an exception" do
      assert_raise ActiveRecord::AssociationTypeMismatch do
      @tag_instance.tag = @sample
      end
    end  
  end

  context "move to asset_group" do
    setup do
      @current_user = Factory :user

      @study   = Factory :study
      @study_2 = Factory :study

      @study_to = Factory :study
      
      @sample = Factory :sample
      @sample_tube = Factory :asset, :sti_type => "SampleTube", :material  => @sample
      @library_tube = Factory :asset, :sti_type => "LibraryTube", :material  => @sample

      @sample_2 = Factory :sample
      @sample_tube_2 = Factory :asset, :sti_type => "SampleTube", :material  => @sample_2
      @library_tube_2 = Factory :asset, :sti_type => "LibraryTube", :material  => @sample_2

      @multiplex_tube = Factory :asset, :sti_type => "MultiplexedLibraryTube"
      @lane = Factory :asset, :sti_type => "Lane"

      @study_sample = Factory :study_sample, :study => @study, :sample => @sample
      @study_sample = Factory :study_sample, :study => @study_2, :sample => @sample_2

      @asset_group_to         = Factory :asset_group, :study => @study
      @asset_group_asset_to   = Factory :asset_group_asset, :asset =>  @sample_tube, :asset_group => @asset_group_to
      @asset_group_to_2       = Factory :asset_group, :study => @study_2
      @asset_group_asset_to_2 = Factory :asset_group_asset, :asset =>  @sample_tube_2, :asset_group => @asset_group_to_2

      @asset_link = Factory :asset_link, :ancestor => @sample_tube, :descendant => @library_tube
      @asset_link = Factory :asset_link, :ancestor => @sample_tube_2, :descendant => @library_tube_2
      @asset_link = Factory :asset_link, :ancestor => @library_tube, :descendant => @multiplex_tube
      @asset_link = Factory :asset_link, :ancestor => @library_tube_2, :descendant => @multiplex_tube
      @asset_link = Factory :asset_link, :ancestor => @multiplex_tube, :descendant => @lane

      @submission   = Factory :submission, :study => @study
      @request_type = Factory :request_type
      @workflow     = Factory :submission_workflow
      
      @request_sampletube  = Factory :request, :study => @study, :request_type => @request_type, :sample => @sample, :asset => @sample_tube, :submission => @submission, :workflow => @workflow
      @request_librarytube = Factory :request, :study => @study, :request_type => @request_type, :sample => @sample, :asset => @library_tube, :submission => @submission, :workflow => @workflow
      @request_sampletube2 = Factory :request, :study => @study, :request_type => @request_type, :sample => @sample_2, :asset => @sample_tube_2, :submission => @submission, :workflow => @workflow
      @request_multiplex   = Factory :request, :study => @study, :request_type => @request_type, :sample => @sample, :asset => @multiplex_tube, :submission => @submission, :workflow => @workflow
      @request_lane        = Factory :request, :study => @study, :request_type => @request_type, :sample => @sample, :asset => @lane, :submission => @submission, :workflow => @workflow

      @new_assets_name = ""

      @sample_to = Factory :sample
      @asset_to = Factory :asset, :name => @sample_to.name, :material => @sample_to
      @asset_group_to_new = Factory :asset_group, :name => "Asset_Exist_To", :study => @study_to
      @asset_group_asset_to = Factory :asset_group_asset, :asset => @asset_to , :asset_group => @asset_group_to_new

    end
    should "return true and requests have right study, sample has linked to new_asset_group, update study_sample. " do
      @result = @lane.move_to_asset_group(@study, @study_to, @asset_group_to_new, @new_assets_name, @current_user)
      assert_equal true, @result

      @request_sampletube.reload
      assert_equal @request_sampletube.study_id, @study_to.id
      
      @request_librarytube.reload 
      assert_equal @request_librarytube.study_id, @study_to.id  

      @request_sampletube2.reload 
      assert_equal @request_sampletube2.study_id, @study_to.id   

      @request_multiplex.reload 
      assert_equal @request_multiplex.study_id, @study_to.id   

      @request_lane.reload
      assert_equal @request_lane.study_id, @study_to.id
      
      @sample_tube.reload
      assert_equal @sample_tube.asset_groups.find_all_by_study_id(@study_to.id).first, @asset_group_to_new

      @sample_tube_2.reload
      assert_equal @sample_tube_2.asset_groups.find_all_by_study_id(@study_to.id).first, @asset_group_to_new

      @sample.reload
      assert_not_equal @sample.study_samples.find_all_by_study_id(@study_to.id), []
      
      @sample_2.reload
      assert_not_equal @sample_2.study_samples.find_all_by_study_id(@study_to.id), []
    end
    
  end


  context "move to asset_group (Dag structure)" do
    setup do
      @current_user = Factory :user

      @study   = Factory :study
      @study_to = Factory :study

      @sample = Factory :sample
      @sample_tube = Factory :asset, :sti_type => "SampleTube", :material  => @sample
      @library_tube = Factory :asset, :sti_type => "LibraryTube", :material  => @sample
      @library_tube_2 = Factory :asset, :sti_type => "LibraryTube", :material  => @sample
      @multiplex_tube = Factory :asset, :sti_type => "MultiplexedLibraryTube"

      @study_sample = Factory :study_sample, :study => @study, :sample => @sample

      @asset_group_to         = Factory :asset_group, :study => @study
      @asset_group_asset_to   = Factory :asset_group_asset, :asset =>  @sample_tube, :asset_group => @asset_group_to


      @asset_link = Factory :asset_link, :ancestor => @sample_tube, :descendant => @library_tube
      @asset_link = Factory :asset_link, :ancestor => @sample_tube, :descendant => @library_tube_2
      @asset_link = Factory :asset_link, :ancestor => @library_tube, :descendant => @multiplex_tube
      @asset_link = Factory :asset_link, :ancestor => @library_tube_2, :descendant => @multiplex_tube


      @submission   = Factory :submission, :study => @study
      @request_type = Factory :request_type
      @workflow     = Factory :submission_workflow

      @request_sampletube  = Factory :request, :study => @study, :request_type => @request_type, :sample => @sample, :asset => @sample_tube, :submission => @submission, :workflow => @workflow
      @request_librarytube = Factory :request, :study => @study, :request_type => @request_type, :sample => @sample, :asset => @library_tube, :submission => @submission, :workflow => @workflow
      @request_multiplex   = Factory :request, :study => @study, :request_type => @request_type, :sample => @sample, :asset => @multiplex_tube, :submission => @submission, :workflow => @workflow

      @new_assets_name = ""

      @sample_to = Factory :sample
      @asset_to = Factory :asset, :name => @sample_to.name, :material => @sample_to
      @asset_group_to_new = Factory :asset_group, :name => "Asset_Exist_To", :study => @study_to
      @asset_group_asset_to = Factory :asset_group_asset, :asset => @asset_to , :asset_group => @asset_group_to_new

    end
    should "return true and requests have right study, sample has linked to new_asset_group, update study_sample. " do
      @result = @library_tube.move_to_asset_group(@study, @study_to, @asset_group_to_new, @new_assets_name, @current_user)
      assert_equal true, @result

      @request_sampletube.reload
      assert_equal @request_sampletube.study_id, @study_to.id

      @request_librarytube.reload 
      assert_equal @request_librarytube.study_id, @study_to.id

      @sample.reload
      assert_not_equal @sample.study_samples.find_all_by_study_id(@study_to.id), []
    end
  end
  
  context "#assign_relationships" do
    context "with the correct arguments" do
      setup do
        @asset = Factory :asset
        @parent_asset_1 = Factory :asset
        @parent_asset_2 = Factory :asset
        @parents = [@parent_asset_1, @parent_asset_2]
        @child_asset = Factory :asset
  
        @asset.assign_relationships(@parents, @child_asset)
      end
  
      should "add 2 parents to the asset" do
        assert_equal 2, @asset.parents.size
      end
  
      should "add 1 child to the asset" do
        assert_equal 1, @asset.children.size
      end
  
      should "set the correct child" do
        assert_equal @child_asset, @asset.children.first
      end
  
      should "set the correct parents" do
        assert_equal @parents, @asset.parents
      end
    end
  
    context "with the wrong arguments" do
      setup do
        @asset = Factory :asset
        @parent_asset_1 = Factory :asset
        @parent_asset_2 = Factory :asset
        @parents = [@parent_asset_1, @parent_asset_2]
        @child_asset = Factory :asset
  
        @asset.assign_relationships(@parent_asset_2, [])
      end
  
      should "not create any parents" do
        assert @asset.parents.empty?
      end
  
      should "not create any children" do
        assert @asset.child.nil?
      end
    end
  end
end
