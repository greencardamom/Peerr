#!/usr/local/bin/gawk -bE     

#
# peerr removes the template {{Peer review}} from talk pages when no longer needed. ie. the template was added more than 7 
# days ago indicating the peer review processes has stalled or was not properly initiated.
#
# https://en.wikipedia.org/wiki/User:GreenC_bot/Job_20
#

# The MIT License (MIT)
#    
# Copyright (c) April 2021 User:GreenC at en.wikipedia.org
#   
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR                   
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

# Download a copy of library.awk here: https://github.com/greencardamom/BotWikiAwk/tree/master/lib

@include "library.awk"

#
# entity_exists - see if a page on Wikipedia exists
#   eg. if ( ! entity_exists("Gutenberg author") ) print "Unknown page"
#
function pageExists(entity   ,url,jsonin) {

        url = "https://en.wikipedia.org/w/api.php?action=query&titles=" urlencodeawk(entity) "&format=json"
        jsonin = http2var(url)
        if(empty(jsonin) || jsonin ~ "\"missing\"")
            return 0
        return 1
}

#
# Add a new entry to list
#
function addList(page,  mainPage,archive) {

  archive = getArchive(page)
  if(empty(archive)) {
    stdErr(dateeight() ": Unable to determine archive number (template missing?): " page)
    print(dateeight() ": Unable to determine archive number (template missing?): " page) >> Logerror
    return 0
  }
  L[page]["page"] = page
  mainPage = L[page]["page"]
  sub(/^Talk:/, "", mainPage) 
  L[page]["prpage"] = "Wikipedia:Peer review/" mainPage "/" archive
  L[page]["date"] = dateeight() # default to todays date
  return 1

}

#
# Check if page exists in list
#
function inList(page, k) {
  for(k in L) {
    if(L[k]["page"] == page) 
      return 1
  }
  return 0
}

function loadList(file,  a,b,page,i) {
  if(!checkexists(file)) return
  for(i = 1; i <= splitn(file, a, i); i++) {
    if(split(a[i], b, " ---- ") == 3) {
      page = strip(b[1])
      L[page]["page"] = page
      L[page]["date"] = strip(b[2])
      L[page]["prpage"] = strip(b[3])
    }
  }
}

function saveList(file) {
  if(checkexists(file)) 
    sys2var(Exe["rm"] " -r " file)
  for(page in L) 
    print L[page]["page"] " ---- " L[page]["date"] " ---- " L[page]["prpage"] >> file
  
}

#
# Number of days between today and date in L[page]["date"] rounded down
#
function numberDays(page,   old,new,c,a) {

  old = sys2var(Exe["date"] " '+%s' -d " L[page]["date"])
  new = sys2var(Exe["date"] " '+%s' -d " dateeight())
  c = (new - old) / 86400
  split(c, a, /[.]/)
  return a[1]

}

#
# Retrieve 'archive1' or 'archive2', etc.. defined in {{peer review|archive=1}}
#
function getArchive(page,  fp,d,dd,ddd,tries) {

  # wikiget runs under gawk, which can crash intermittently (heap double-free) and
  # return empty output. Pages in this category always contain {{Peer review}}, so an
  # empty response means a failed fetch, not a missing template. Retry before giving up.
  for(tries = 1; tries <= MaxTries; tries++) {
    fp = sys2var(Exe["wikiget"] " -f -w " shquote(page)) # -f = don't follow redirects
    if(!empty(strip(fp)))
      break
    if(tries < MaxTries)
      sys2var(Exe["sleep"] " 3")
  }
  if(empty(strip(fp))) {
    stdErr(dateeight() ": wikiget returned empty after " MaxTries " tries (gawk crash?): " page)
    print(dateeight() ": wikiget returned empty after " MaxTries " tries (gawk crash?): " page) >> Logerror
    return
  }

  if(match(fp, templateRE "[ ]*(\\n)?", d) > 0) {
    d[0] = strip(d[0])
    if(match(d[0], /archive[[:space:]]*=[[:space:]]*[0-9]{1,2}/, dd) > 0) {
      match(dd[0], /[0-9]{1,2}/, ddd)
      return "archive" ddd[0]
    }
    return "archive1"
  }
  else if(match(stripnowiki(fp), /[#]redirect[^\n]+[^\n]/, dd) > 0) {
    stdErr(dateeight() ": Aborting: [[" page "]] contains: " dd[0])
    print(dateeight() ": Aborting: [[" page "]] contains: " dd[0]) >> Logerror
  }
}

#
# Delete template from page
#
function deleteTemplate(page,  temp,fp,d,command,result,comres) {

  result = 0
  temp = Home "temp.txt"
  fp = sys2var(Exe["wikiget"] " -w " shquote(page))
  if(match(fp, templateRE, d) > 0) {
    fp = gsubs(d[0], "", fp)    # gsubs to remove duplicate instances of the first instance of the template in the page
    print fp > temp
    close(temp)
    command = Exe["wikiget"] " -E " shquote(page) " -S " shquote("Removing {{Peer review}} after " MaxDays " days without creation of [[" L[page]["prpage"] "]] per [[User:GreenC bot/Job 20]]") " -P " shquote(temp) 
    comres = sys2var(command)
    if(comres != "Success") {
      stdErr(dateeight() ": Unable to upload (" comres "): " command)
      print(dateeight() ": Unable to upload (" comres "): " command) >> Logerror
    }
    else {
      print(dateeight() ": Successful upload: " command) >> Logfile
      result = 1
    }
  }
  else {
    stdErr(dateeight() ": Unable to find template in page: " page)
    print(dateeight() ": Unable to find template in page: " page) >> Logerror
  }
  return result
}

function main(  cat,a,i,watch,b) {

  loadList(List)
  cat = sys2var(Exe["wikiget"] " -c \"Peer review requests not opened\"")

  # Remove template from page and from list, if date expired
  # Add to list if in category but not in list

  for(i = 1; i <= splitn(cat "\n", a, i); i++) {
    a[i] = strip(a[i])
    if(a[i] !~ /^Talk:/)
      continue
    if(inList(a[i])) {
      if(int(numberDays(a[i])) >= MaxDays) {    # number of days between now and L[page]["date"] >= MaxDays
        if(!pageExists(L[a[i]]["prpage"])) {
          if(deleteTemplate(a[i]))
            delete L[a[i]]
        }
      }      
    }
    else 
      addList(a[i])
  }

  # Remove from list if not in category

  for(b in L) { 
    watch = 0
    for(i = 1; i <= length(a); i++) {
      if(L[b]["page"] == a[i])
        watch = 1
    }
    if(watch == 0) 
      delete L[b]
  }

  saveList(List)

}

BEGIN {

  IGNORECASE = 1

  # WMF policy requires a contact address in the user-agent. Read it from a file so it is
  # never committed, and so it can be rotated in one place.
  EmailFP = "/home/greenc/scripts/secrets/greenc.email"
  Agent = "medic-peerr/1.0 (https://en.wikipedia.org/wiki/User:GreenC; " strip(readfile(EmailFP)) ")"

  Home = "/home/greenc/toolforge/peerr/"

  MaxDays = 7    # Number of days to wait before removing template

  MaxTries = 3   # Number of times to retry wikiget when it returns empty (gawk crash)

  # Template:Peer review
  templateRE = "[{][{][[:space:]]*(peer review|peerreview|pr)[[:space:]]*[|][^}]*[}][}]"

  # wikiget : https://github.com/greencardamom/Wikiget
  Exe["wikiget"] = "/home/greenc/scripts/wikiget.awk"
  Exe["timeout"] = "/usr/bin/timeout"
  Exe["wget"]    = "/usr/bin/wget"
  Exe["date"]    = "/bin/date"
  Exe["rm"]      = "/bin/rm"
  Exe["sleep"]   = "/bin/sleep"
  Exe["push"]    = Home "push"

  List = Home "www/list.txt"

  Logfile = Home "www/loguploads.txt"
  Logerror = Home "www/logerrors.txt"

  main()

  # Mirror output in ~/www directory to Toolforge
  sys2var(Exe["push"] " peerr")

}

