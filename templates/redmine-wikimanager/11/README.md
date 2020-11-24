# Rancher to Redmine wiki exporter
Exports multiple rancher hosts, stacks and containers information to tables in wiki pages in Redmine. 

## Prerequisite

You need to generate an API key in every rancher from a readonly user. Also, the redmine user needs to have permission on the project to update wiki pages. 

## Stack Variables


1. Rancher configuration - can be multiple lines, each representing a rancher, with the format - rancher url, access key, secret key ( separated by commas)
2. Redmine url - The main url of the redmine instance
3. Redmine API key - Belongs to the user that will update the wiki pages
4. Redmine wiki project - The redmine project where the wiki pages are
5. Redmine wiki hosts page 
6. Redmine wiki stacks page  
7. Redmine wiki containers page 
8. Debug on - Choose Yes to enable debug logging
9. Crontab schedule (UTC) - uses https://godoc.org/github.com/robfig/cron#hdr-CRON_Expression_Format
10.  Timezone 


## Usage

The stack needs a rancher_crontab stack to start it according to the Run Schedule, otherwise it will only run once. If you do not set all of the Redmine related variables, the generated pages will be written in docker logs. 

