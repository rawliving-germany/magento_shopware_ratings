# Convert magento 2.x to shopware ratings

(Notes and scripts from/for the process, specific usecase).

## DB

In magento, ratings are linked to reviews which can be linked to probably any
eav-receiver.

In shopware, these lives in the table `s_articles_vote`.

## Plan of action

### 1 get the ratings/reviews from the magento instance and store them as json
### 2 read the json and insert into the shopware database

In this setup, the SKU of a product is stored in magento in the
`catalog_product_entity`s `SKU` column. In shopware it is in the
`s_articles_details` `ordernumber` column (hence, a lookup is necessary)

## Usage

Clone the repository, run `bundle`, then `./magento_comments.rb` which will tell
you the relevant options.

## License

Code is copyright 2020 Felix Wolfsteller and released under the AGPLv3+ .
However, these are only notes and scripts for a specific usecase. If you have a
(tiny) budget and need or some ideas about improvements, get in contact.
