# SPDX-FileCopyrightText: 2020 Felix Wolfsteller
#
# SPDX-License-Identifier: AGPL-3.0-or-later

ShopwareReview = Struct.new(:articleID,
                            :name,
                            :headline,
                            :comment,
                            :points,
                            :datum,
                            :active,
                            :sku,
                            keyword_init: true)

