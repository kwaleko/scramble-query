# scramble-query
## Problem
on the phase 2 of a project X, we needed to make the nessary development so dummy data should be available , it was impossible to take a backup from the production data due to condiential problem

## Solution
1- make a query that scrumble all the database table by table and it scrumble each record based on random key

2- take a backup from the production and restore it on the test server

3- restore the backup on the development server

4- run the scrumble query on the dev server
