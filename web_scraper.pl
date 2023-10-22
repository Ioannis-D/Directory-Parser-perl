#!/usr/bin/env perl

# A web-scraper that completes the Directory_parser.pl program (github.com/Ioannis-D/Directory-Parser-perl).
# The script downloads file extensions for different file categories stored in .txt files.

# Created by: Ioannis Doganos | https://github.com/Ioannis-D

use strict;
use warnings;

use LWP::UserAgent;
use IO::Socket::SSL;

my $ua = LWP::UserAgent->new(cookie_jar=>{});

$ua->ssl_opts(
    'SSL_verify_mode' => IO::Socket::SSL::SSL_VERIFY_NONE, 
    'verify_hostname' => 0
);

# Create a hash containing:
    # a) the filename of the txt file as the key 
    # b) the final part of the file-extensions.org website as the value
my %webpages = (
                'Archive and compressed' => 'archive-and-compressed-files',
                'Audio' => 'audio-and-sound-files',
                'Database' => 'database-files',
                'E-book' => 'e-book-files',
                'Email' => 'email-related-data-files',
                'Video' => 'movie-video-multimedia-files',
            );

# Create the 'txt_files' directory where the txt files will be stored
mkdir './txt_files/';

# Parse through every extension
while (my ($name, $page) = each %webpages) {
    $name = './txt_files/' . $name . '.txt'; # Create the txt file path and name
    my $url = 'https://www.file-extensions.org/filetype/extension/name/' . $page; # Create the real url

    print("\nCreating the $name extensions");

    # Make the request and read the content of the page
    my $request = new HTTP::Request('GET', $url);
    
    my $response = $ua->request($request);
    
    unless($response->is_success()) {
        die $response->status_line();
    }
    
    my $content = $response->decoded_content();
    
    # Extract only the extensions and store them in @extensions
    my @extensions = $content =~ m|<strong class="color3">(.+?)</strong>|sig;

    # Write the text file with the extensions separated by | (in order to be used as a regex in the Directory_parser.pl)
    open(FH, '>', $name) or die $!;
    foreach my $extension (@extensions) {
        print FH $extension . '|';
    }
    close(FH);
    print("\n$name was created\n");
}

print("\nCompleted\n\n");
print("You can now use the Directory_parser.pl\n");
