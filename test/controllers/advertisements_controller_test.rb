require "test_helper"

class AdvertisementsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "get advertisement with active & matching campaign" do
    campaign = active_campaign
    property = matched_property(campaign)
    get advertisements_url(property, format: :js)
    assert_response :success
    assert response.body.include?("codeFundElement.innerHTML = '<div id=\"cf\"")
  end

  test "get advertisement with active & geo matching campaign" do
    self.remote_addr = "192.168.0.100"
    campaign = active_campaign(country_codes: ["US"])
    property = matched_property(campaign)
    get advertisements_url(property, format: :js)
    assert_response :success
    assert response.body.include?("codeFundElement.innerHTML = '<div id=\"cf\"")
  end

  test "get advertisement with active but no geo matching campaigns" do
    self.remote_addr = "192.168.0.100"
    campaign = active_campaign(country_codes: ["CA"])
    property = matched_property(campaign)
    get advertisements_url(property, format: :js)
    assert_response :success
    assert response.body.include?("CodeFund does not have an advertiser for you at this time.")
  end

  test "get advertisement with no matching campaigns" do
    campaign = inactive_campaign
    property = matched_property(campaign)
    get advertisements_url(property, format: :js)
    assert_response :success
    assert response.body.include?("CodeFund does not have an advertiser for you at this time.")
  end

  test "get advertisement with fallback campaign" do
    campaign = fallback_campaign
    property = matched_property(campaign)
    get advertisements_url(property, format: :js)
    assert_response :success
    assert response.body.include?("codeFundElement.innerHTML = '<div id=\"cf\"")
  end

  test "get advertisement with fallback campaign when property doesn't allow fallbacks" do
    campaign = fallback_campaign
    property = matched_property(campaign)
    property.update! prohibit_fallback_campaigns: true
    get advertisements_url(property, format: :js)
    assert_response :success
    assert response.body.include?("CodeFund does not have an advertiser for you at this time.")
  end

  test "get sponsor advertisement" do
    Impression.delete_all
    campaign = active_campaign(country_codes: ["US"])
    campaign.creatives.each do |creative|
      creative.standard_images.destroy_all
      creative.update! creative_type: ENUMS::CREATIVE_TYPES::SPONSOR
      CreativeImage.create! creative: creative, image: attach_sponsor_image!(campaign.user)
    end
    property = matched_property(campaign)
    property.update url: "https://github.com/gitcoinco/code_fund_ads"
    campaign.update assigned_property_ids: [property.id]
    ip = ip_address("US")

    assert Impression.count == 0
    assert campaign.sponsor?
    assert property.restrict_to_sponsor_campaigns?
    assert campaign.creatives.size == 1
    assert campaign.sponsor_creatives.size == 1

    get advertisements_url(property, format: :svg), headers: {"REMOTE_ADDR": ip, "User-Agent": "Rails/Minitest"}

    assert_response :success
    assert response.headers["Content-Type"] == "image/svg+xml; charset=utf-8"
    assert response.body == campaign.creatives.first.sponsor_image.download
    assert Impression.count == 1

    impression = Impression.first

    assert impression.campaign == campaign
    assert impression.property == property
    assert impression.ad_template == "sponsor"
    assert impression.creative == campaign.sponsor_creatives.first
    assert impression.ip_address == Impression.obfuscate_ip_address(ip)
  end

  test "get sponsor advertisement catch-all" do
    Impression.delete_all
    campaign = active_campaign(country_codes: ["US"])
    property = matched_property(campaign)
    Campaign.destroy_all
    ip = ip_address("US")

    get advertisements_url(property, format: :svg), headers: {"REMOTE_ADDR": ip, "User-Agent": "Rails/Minitest"}

    assert Impression.count == 0
    assert_response :success
    assert response.headers["Content-Type"] == "image/svg+xml; charset=utf-8"
    assert response.body == File.read(File.join("app/assets/images/sponsor-catch-all.svg"))
  end

  private

  def active_campaign(country_codes: [])
    campaign = campaigns(:premium)
    campaign.update!(
      status: ENUMS::CAMPAIGN_STATUSES::ACTIVE,
      start_date: 1.month.ago,
      end_date: 1.month.from_now,
      country_codes: country_codes,
      keywords: ENUMS::KEYWORDS.keys.sample(10)
    )
    campaign.creative.add_image! attach_large_image!(campaign.user)
    campaign.organization.update balance: Monetize.parse("$10,000 USD")
    campaign
  end

  def inactive_campaign
    campaign = campaigns(:premium)
    campaign.update!(
      status: ENUMS::CAMPAIGN_STATUSES::ARCHIVED,
      start_date: 6.months.ago,
      end_date: 4.months.ago,
      keywords: ENUMS::KEYWORDS.keys.sample(10)
    )
    campaign
  end

  def fallback_campaign
    campaign = campaigns(:premium)
    campaign.update!(
      status: ENUMS::CAMPAIGN_STATUSES::ACTIVE,
      start_date: 1.month.ago,
      end_date: 1.month.from_now,
      keywords: [],
      fallback: true
    )
    campaign.creative.add_image! attach_large_image!(campaign.user)
    campaign
  end

  def matched_property(campaign, fixture: :website)
    property = properties(fixture)
    property.update! keywords: campaign.keywords.sample(5)
    property
  end
end
