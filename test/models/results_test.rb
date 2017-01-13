require "test_helper"
require "byebug"
class ResultTest < ActiveSupport::TestCase

  # Validations Tests
  should validate_presence_of(:url)
  should_not allow_value("blah/www.foo.com").for(:url)
  should allow_value("http://www.foo.com").for(:url)
  should validate_uniqueness_of(:url)

  # Association Tests
  should belong_to(:status)
  should belong_to(:user)
  should have_many(:task_results)
  should have_many(:result_flags)
  should have_many(:result_attachments)
  should have_many(:subscribers)
  should have_many(:events)
  should have_many(:tasks).through(:task_results)
  should have_many(:flags).through(:result_flags)
  should have_many(:stages).through(:result_flags)
  should have_many(:taggings).dependent(:delete_all)

  fixture_result = Result.first
  github_result = Result.last

  # Class Method Tests
  test "should generate a csv file" do
    csv = Result.to_csv
    assert_includes(csv, "id,title,url,status_id,created_at,updated_at,domain,user_id,content,metadata_archive,metadata,metadata_hash")
  end


  test "should generate an array of valid column names" do
    assert_equal(Result.valid_column_names, ["id", "title", "url", "status_id", "created_at", "updated_at", "domain", "user_id", "screenshot", "link"])
  end

  # Class Method Search Tests
  test "should perform a default result search" do
    ransack, results = Result.perform_search(q={"status_id_includes_closed"=>"0", "g"=>{"0"=>{"m"=>"or", "status_id_null"=>1, "status_closed_not_eq"=>true}}})
    assert_equal(results.length, 2)
  end

  test "should perform a tag result search" do
    ransack, results = Result.perform_search(q={"tags_id_eq"=>1})
    assert_equal(results.length, 1)
  end

  test "should perform a single metadata hash element result search" do
    ransack, results = Result.perform_search({metadata_search: "curl_metadata:Server==\"shakti-prod i-0ee8e795b8bde9360\",vulnerability_count:closed==1"}, 1, 25, {include_metadata_column:true})
    assert_equal(results.length, 1)
  end

  test "should perform a single metadata array element result search" do
    ransack, results = Result.perform_search({metadata_search: "array_test@>[\"1\"]"}, 1, 25, {include_metadata_column:true})
    assert_equal(results.length, 1)
  end

  test "should perform a multi metadata hash element result search" do
    ransack, results = Result.perform_search({url_cont: "netflix", metadata_search: "curl_metadata:Server==\"shakti-prod i-0ee8e795b8bde9360\""}, 1, 25, {include_metadata_column:true})
    assert_equal(results.length, 1)
  end


  test "should perform a negative metadata  element result search" do
    ransack, results = Result.perform_search({metadata_search: "github_analyzer:private!=false"}, 1, 25, {include_metadata_column:true})
    assert_equal(results.length, 1)
  end
  #edx:hysterix@>["HystrixMembershipCreateAutoLoginToken"]

  # Instance Method Tests
  test "executes creat_task_event correctly" do
    Thread.current[:current_task] = 1
    fixture_result.create_task_event
    assert_equal(Thread.current["current_results"]["created"], [1])
  end

  test "executes traverse_metadata correctly" do

    assert_equal(fixture_result.traverse_metadata(["array_test"]), {"array_test"=>["1", "2"]})
  end

  test "sets tag_list on a result" do
    Thread.current[:current_task] = 1
    fixture_result.tag_list="Foo"
    assert_equal(fixture_result.tag_list="Foo", "Foo")
  end

  test "executes set_status on result" do
    github_result.set_status
    assert_equal(github_result.status_id, 1)
  end


  test "executes update_task_event correctly" do
    Thread.current[:current_task] = 1
    fixture_result.update_task_event
    assert_equal(Thread.current["current_results"]["updated"], [1])
  end

  test "executes tag_lit correctly" do
    fixture_result.update_task_event
    assert_equal(fixture_result.tag_list, "Foo")
  end

  test "ensures tag_list setter executed correctly" do
    assert_equal(fixture_result.tags.first.name, "Foo")
  end

  test "create an attachment from url" do
    assert_equal(fixture_result.create_attachment_from_url("https://www.google.com/images/branding/googlelogo/2x/googlelogo_color_272x92dp.png"), true)
  end

  test "do not create attachment since url is not image" do
    assert_equal(fixture_result.create_attachment_from_url("https://www.google.com/"), false)
  end

  if Rails.configuration.try(:sketchy_url).present?
    test "create attachment from sketchy" do
      fixture_result.create_attachment_from_sketchy("https://www.google.com/")
      assert_equal(Fixnum, fixture_result.metadata["sketchy_ids"].first.class)
    end
  end


  # test "get a result record" do
  #   result = Result.first
  #   assert_not_nil(result)
  # end

end
