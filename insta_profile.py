#!/usr/bin/env python3
"""Usage: insta_profile.py <username>  (run with the instaloader venv python)"""
import sys
import instaloader

user = sys.argv[1]
L = instaloader.Instaloader()
try:
    p = instaloader.Profile.from_username(L.context, user)
    print("Username:", p.username)
    print("User ID:", p.userid)
    print("Full name:", p.full_name)
    print("Private:", p.is_private)
    print("Verified:", p.is_verified)
    print("Followers:", p.followers)
    print("Following:", p.followees)
    print("Posts:", p.mediacount)
    print("Bio:", p.biography)
    print("External URL:", p.external_url)
    print("Profile URL:", f"https://www.instagram.com/{p.username}/")
except Exception as e:
    print("Error:", e)
    print("Instagram often blocks anonymous requests (401 / login required / rate limit).")
    print("Wait a few minutes and retry. Do not use fake accounts to log in.")
