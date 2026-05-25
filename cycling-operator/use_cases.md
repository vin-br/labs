# Use Cases for the dataset

## In HTML

### 1. Tour List Overview

What to display:
A grid or list of tours with cards for each tour.

Each card should show:

- Tour name
- Short description
- Category (e.g., "easy", "moderate")
- Distance and duration
- Price
- Availability (e.g., "5 spots left")
- A thumbnail image (if available)
- A "View Details" button

### 2. Guide Profiles

What to display:
A list of guides 

Each card should show
- names
- pictures
- nationalities
- spoken languages
- qualifications

### 3. French-Speaking Guides

What to display:
A filtered list of guides who speak French.

Each card should show
- names
- pictures
- nationalities
- spoken languages
- qualifications

-> Shows how to filter data in XSLT based on specific criteria (language spoken).

### 4. Map of Tour Locations

What to display:
- A map (using Leaflet.js or Google Maps API) showing the tour route or start/end points.

Could be added with more work but I think it needs to rework the XML structure to add coordinates to each step:
> Markers for each step, with popups showing details (distance, surface, elevation).

-> use case used for the python implementation of a scenario.

### 5. Emergency Contact Dashboard

What to display:
- A list of clients with their emergency contact details.
 
Each entry should show:
  - Tour name
  - Client name
  - Client contact information
  - Emergency contact name
  - Emergency contact phone number
  - Relation to client
  - Bike details (if issue with the bike during the tour)

### 6. Bike Inventory Management Dashboard

What to display:
- A list of all bikes with their details.

Each entry should show:
  - Bike ID
  - Type (mountain, road, electric bike + autonomy)
  - Size
  - Availability status
  - Location (which tour it's assigned to, if any)
  - Rate of rental
  - Option to filter by type or availability

### 7. Booking System

What to display:

- A form to book a tour or package.
- Fields for client details, payment, and selected options (bike, package, etc.).

-> should insert the new data correctly into the xml file (maybe through a transformation xslt ?)

- Confirmation page after booking (reads from the updated xml file, by filtering with booking id and client name).

Option to filter by language or qualification.

### 8. Admin Dashboard (Optional)

What to display:

- Statistics (e.g., number of tours, bookings, revenue).
- Tables for managing tours, guides, bikes, and bookings.
- Charts (e.g., booking trends, tour popularity).

## In JSON

### 1. Data on packages

What to store:
The list of all packages selected (all occurences of it, and the tours they are each associated to)

### 2. Data on bikes

What to store:
A list of all occurencies of the bikes booked, which tour they were booked for with the associated distances of the tour and the type of terrain (percentages of each)

### 3. Mobile App: Offline Tour Data

Use Case:
Allow users to download tour details (maps, steps, accommodations) for offline use during the tour.
What to Extract:

- tour_steps:
    - coordinates (for offline maps)
    - address, distance_from_previous_point
    - accomodations (address, included amenities)
    - activity (name, duration, price)

### 4. API for Third-Party Partners

Use Case:
Share tour, guide, or package data with travel agencies or affiliate websites.
What to Extract:

- Subset of data depending on the partner’s needs:

    - tours (public details: name, description, price, availability)
    - guides (name, languages, qualifications)
    - packages (name, price, description)

### 5. Customer Support: Booking History

Use Case:
Allow customer support to view a user’s booking history and details.
What to Extract:

- bookings for a specific client:

    - booking_date
    - package (name, code)
    - payment (status, amount)
    - tour (name, dates)

### 6. Data Analysis: Popular Tours and Trends

Use Case:
Analyze which tours are most popular, which bikes are rented most often, or which guides are in demand.
What to Extract:

- Aggregated data from:

    - tours (category, distance, price)
    - bookings (number of bookings per tour/package)
    - bikes (rental frequency, types)
    - guides (number of tours led)
