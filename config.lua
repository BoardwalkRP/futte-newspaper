Config = {}

Config.BuyNewspaperText = 'Buy Newspaper' -- Text shown with qb-target
Config.BuyNewspaperIcon = 'fas fa-newspaper' -- Icon shown with qb-target
Config.Price = 5 -- Price of buying the newspaper
Config.AmountOfNews = 10 -- Amount of news to be fetched from the database
Config.AmountOfSentences = 10 -- Amount of prison sentences to be fetched from the database
Config.AdvertisementCooldown = 10 -- Time in seconds
Config.AdvertisementPrice = 5
Config.NewspaperItem = {
    name = 'newspaper', label = 'Newspaper', weight = 10, type = 'item', image = 'newspaper.png', unique = false , useable = true, shouldClose = true, combinable = nil, description = 'Los Santos Newspaper'
}
