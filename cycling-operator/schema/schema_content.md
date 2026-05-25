# Schema Content

Tours
    tour
        tour name
        company
            name
            contact
                email
                phone number
            address
                street
                city 
                code
                country  

        short description
        long description
        category (gobal difficulty)
        distance
        duration
            duration days
            start date
            end date
        price
            amount
            currency
        guide @idref
        tour_availability
            capacity (max participants)
            current number of participants
            availability (open, waitlist, sold out)
        starting point
            coordinates
                longitude
                latitude
            address
                street
                city 
                code
                country
        destination
            coordinates
                longitude
                latitude
            address
            city
            country
        tour steps
            step @order (1, 2, ...)
                coordinates
                    longitude
                    latitude
                address
                    street
                    city 
                    code
                    country
                distance from previous point
                surface type
                terrain elevation
                difficulty

                activity (events) available(optional)
                    name
                    type
                    address
                        street
                        city 
                        code
                        country
                    duration
                    price (optional)
                        amount
                        currency
                
                accomodations (optional)
                    type (hotel, hostel, b&b, camping,...)
                    address
                        street
                        city 
                        code
                        country
                    price (per night)  
                        amount 
                        currency
                    included 
                        breakfast (optional)
                        lunch (optional)
                        dinner (optional)
                        bedding (optional)
                        wifi (optional)
                    excluded (optional)
                        breakfast (optional)
                        lunch (optional)
                        dinner (optional)
                        bedding (optional)
                        wifi (optional)

        bikes 
            bike @id
                model 
                type (road, hybrid, ...)
                    -> if electric autonomie
                gear count
                size
                weight
                rental price per day
                    amount
                    currency
                bike availability

                booking
                    booking date
                    package @idref
                    client
                        firstname
                        lastname
                        contact
                            email
                            phone number
                        address
                            street
                            city 
                            code
                            country
                        nationality
                        emergency contact
                            firstname
                            lastname
                            phone number
                            relation
                    payment 
                        amount paid
                        left to be paid
                        currency
                        method (credic card, etc. )
                        payment status (fully, deposit, ...)  
                       
guides
    guide @id
        firstname
        lastname
        picure
        contact
            email
            phone number
        address
            street
            city 
            code
            country
        nationality
        spoken laguages
            language @id language
        qualifications
            qualification

                       
packages
    package @id              
        name
        price
            amount
            currency
        code
        description

