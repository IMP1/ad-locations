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

# Data Acquisition (sp?)

There is an inital script that goes numerically through IDs from 1 upto 200,000 and scrapes initial ID from the bubbleoutdoor website,
populating the `adverts_partial_address,csv` data file.

Before I realised that there was a way to get the postcode on the buble outdoor website, 
I originally planned to use a geocoding service to identify the postcode from the (sometimes partial) addresses.

Then I realised that there was the `` URL, which provided details about an advert. Using this, I got postcodes.

I'm hoping that all adverts of a specific advert type will have the same properties (dimensions, energy usage, etc.), 
but I think I should have, while getting the postcodes, also gotten dimensions, and the Impressions per week count.

This is a small bit of potential future work, but running the scraper against all ~120k adverts took a couple of days.

# Data Analysis


