<!--
SPDX-FileCopyrightText: 2020 Felix Wolfsteller
SPDX-License-Identifier: AGPL-3.0-or-later
-->
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

Clone the repository, run `bundle`, then

```bash
# Pretty printed json
./magento_comments.rb -u mysqluser -p mysqlpassword -d magentodb --pretty

# Store in file
./magento_comments.rb -u mysqluser -p mysqlpassword -d magentodb > magento.json

# Import (no safety-net!)
./shopware_comments.rb -u mysqluser -p mysqlpassword -d shopwaredb magento.json

# Or, pipe it
./magento_comments.rb -d magentodb | ./shopware_comments.rb -d shopwaredb

```

## License

Code is copyright 2020 Felix Wolfsteller and released under the AGPLv3+ which is
included in the [`LICENSE`](LICENSE) file in full text. The project should be
[reuse](https://reuse.software) compliant.

However, these are only notes and scripts for a specific usecase. If you have a
(tiny) budget and need or some ideas about improvements, just get in contact.
