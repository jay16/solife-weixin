#encoding:utf-8
require File.expand_path "../../../spec_helper.rb", __FILE__

describe "Demo::OpendfindController" do

  it "page index should show successfully" do
    get "/demo/openfind"

    expect(last_response).to be_ok

    visit "/demo/openfind"

    expect(page).to have_title("SOLife | Openfind电子报")

    expect(page.find_field("members[url]").text).to be_empty
    expect(page.find_by_id("membersSubmit").disabled?).to be_true
    expect(page.find_field("template[url]").text).to be_empty
    expect(page.find_by_id("templateSubmit").disabled?).to be_true
  end

  it "should download zip file when click [名单下载]" do
    visit "/demo/openfind"
   
    within("#membersForm") do
      fill_in "members[url]", with: "http://cndemo.openfind.com/china/order/show.php"

      page.find_by_id("membersSubmit").click
    end
    expect(page.response_headers['Content-Type']).to eq("text/csv;charset=utf-8")
    expect(page.response_headers["Content-Disposition"]).to match(/attachment;\s+filename=\"Openfind名单_\d{14}.csv\"/)
  end


  it "should download zip file when click [模板下载]" do
    visit "/demo/openfind"
   
    within("#templateForm") do
      fill_in "template[url]", with: "http://cndemo.openfind.com/china/epaper/2012_12/"

      page.find_by_id("templateSubmit").click
    end
    expect(page.response_headers['Content-Type']).to eq("application/zip")
    expect(page.response_headers["Content-Disposition"]).to match(/attachment;\s+filename=\"openfind 电子报模板_\d{14}.zip\"/)
  end

end