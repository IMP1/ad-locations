# An Analysis of Physical Corporate Advertising

The aim of this project is to quantify the effects of corporate advertising.

There are two datasets currently. 
The first is in `adverts_partial_address.csv` and is a list of the adverts that [BubbleOutdoor](https://bubbleoutdoor.com/) had on their website.
It contains the following values

  * A numeric ID (which is called the URL ID);
  * An advert "type", which is its size, and whether or not it is digital;
  * The Address of the advert, which sometimes can be truncated if it's too long;
  * The weekly cost, if known. If there is no value for this, a default of -1 is used;
  * A BubbleOutdoor-specifc ID, in the format BOUK0000000

There are also URLs that allow more information about an advert, including its postcode, and its dimensions, and its estimated view count ("Impressions per week").
These URLs are queried using the BubbleOutdoor ID.

# Data Acquisition

There is an inital script that goes numerically through IDs and scrapes the corresponding internal BubbleOutdoor ID and some initial advert data from their website,
populating the `adverts_partial_address,csv` data file.

Then I realised that there was a URL, which provided details about an advert given its BubbleOutdoor ID. Using this, I got the postcodes for each advert.

# Data Analysis

Other members of AdBlock Leeds, with more experience in carbon emissions and energy consumption, were involved in the analysis of the data. Their findings are written up in [an article on the AdBlock Leeds website](https://adblockleeds.wordpress.com/2021/01/17/the-ads-in-leeds-consume-as-much-electricity-as-8000-people/).

# Future Development

I'm hoping that all adverts of a specific advert type will have the same properties (dimensions, energy usage, etc.), 
but I think I should have, while getting the postcodes, also gotten dimensions, and the Impressions per week count.

This is a small bit of potential future work, but running the scraper against all ~120k adverts took a couple of days.
