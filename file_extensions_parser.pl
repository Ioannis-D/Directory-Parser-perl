use strict;
use warnings;

$|=1;

sub get_files{
    my $dir = './webpages/';

    # Try to open the directory given and if it fails, show error message and die. 
    unless(opendir(INPUTDIR, $dir)) {
        die "Unable to open $dir directory\n";
    }

    my @files = readdir(INPUTDIR);
    # Doing the above, the @files also contain the sub-directories and also the ./ and ../ directories which is not necessary to be shown as the parser only focuses in the current directory. 

    closedir(INPUTDIR);

    # Only get the files and not sub-directories
    @files = grep {/.+\..+/} @files;

    return @files;
}

# Parse the files of the webpages dictionary with the sub-routine get_files of the Directory_scrapper.pl program.
my @ext_pages = get_files();
foreach my $page (@ext_pages) {
    my $path = './webpages/' . $page;
    do {
        # The $/ has to be changed because if not, the program does not read the whole document as it 'thinks' that the EOF is after some paragraphs.
        local $/ = undef;

        # Read the webpage
        open my $fh, "<", $path
            or die "Could not open $path: $!";
        my $content = <$fh>;
        close($fh);

        # Extract only the extensions and store them in @extensions.
        my @extensions = $content =~ m|<strong class="color3">(.+?)</strong>|sig;
    
        # Create the path and the name of the text file. 
        $page =~ s/(.+\.)(html)/txt_files\/$1txt/;
    
        #Write the text file with the extensions separated by | (in order to be used as a regex in the Directory_scrapper.pl)
        open(FH, '>', $page) or die $!;
        foreach my $extension (@extensions) {
            print FH $extension . '|';
        }
        close(FH);
    };

}
