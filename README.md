# Phone Number OSINT Lab (Educational)

A small Kali Linux toolkit that runs several public-source tools against
one phone number and builds an HTML report.

## Tools used
- phonenumbers (Python): validity, region, carrier, timezone
- PhoneInfoga: public search links and number metadata
- Ignorant: checks which sites a number is registered on
- Google dorks: manual searches for public mentions

## Setup
    sudo apt install -y python3-venv pipx git curl
    python3 -m venv venv && venv/bin/pip install phonenumbers
    pipx install ignorant
    pipx install maigret
    # install PhoneInfoga from its GitHub releases page

## Usage
    ./run.sh +<countrycode><number>

Results are saved in `output/<number>_<date>/`, including `report.html`.

## What this lab shows
A phone number alone reveals public metadata and online footprint only.
It does not reveal a person's name, address, or live location.

## Ethics and legal disclaimer
- Use only on your own number or numbers whose owners gave written consent.
- Do not use this to stalk, harass, or profile anyone.
- In India, processing personal data without consent may violate the
  DPDP Act 2023 and the IT Act 2000.
- Never publish the `output/` folder.

## Extended toolkit (menu)
Run `./osint.sh` for a menu covering:
- Email: Holehe
- Username: Sherlock, Maigret
- Domain: theHarvester, whois, dig
- File metadata: ExifTool
- SpiderFoot web UI (optional)

Install extras:
    pipx install holehe
    pipx install sherlock-project
    sudo apt install -y theharvester libimage-exiftool-perl

Every menu action asks for a consent confirmation. Use only your own
data or data you have written permission to test.

## Instagram profile check (Instaloader)
Menu option 7 reads the public profile data of an Instagram username
(user ID, name, bio, counts). Install with:
    pipx install instaloader
Anonymous access is often rate-limited by Instagram. Use only on your
own account or with written consent. Do not log in with fake accounts.
