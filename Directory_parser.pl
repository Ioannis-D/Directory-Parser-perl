########################################################################
#                    Basic directory scrapper                          #
#             See the files of a directory organised.                  #
#                        Written in Perl.                              #
#                                                                      #
# See below the HELP_MESSAGE for more info about how the program works #
#----------------------------------------------------------------------#
#                   Licence: Apache License 2.0                        #
#                                                                      #
#  Creator: Ioannis Doganos, github: https://github.com/Ioannis-D      #
########################################################################

use strict;
use warnings;

use Getopt::Std;

$|=1;

sub main {
    my %opts;

    getopts('d:r:aegb', \%opts);

    my $dir = $opts{'d'};

    # Check if -d parameter has been given and if not, show message with an example and exit. 
    if(!defined($dir)) {
        usage();
        exit();
    }

    # Use the 'get_files' sub-routine to take all the files of the given directory. 
    my @files = get_files($dir);

    # If the -b argument is passed, print the sub-directories.
    if(defined($opts{'b'})) {
        sub_directories($dir);
    }

    # If the -r argument is given, only return the corresponding files.
    if (defined($opts{'r'})) {
        @files = r_search_files(\@files, $opts{'r'});
    }

    # If the parameter -a is given, do not continue to 'group_files' sub-routine and just print the files and directories without grouping. 
    if(defined($opts{'a'})) {
        print_length(\@files);
        print_files(\@files);
        exit();
    }

    # If the -e argument is passed (without the -a argument), files are grouped by their extension with the use of the ext_group_files sub-routine.
    if(defined($opts{'e'})){
        ext_group_files(\@files);
        exit();
    }

    # Parse the files with the use of 'group_files'. If the -g argument is given, the rest of files are grouped by extension.
    group_files(\@files, $opts{'g'});
}

sub get_files{
    my $dir = shift;

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

sub sub_directories {
    my $dir = shift;

    # The program can recognise directories separated by one (1) or more '/'. 
    # This means that the Parent_directory/Child_directory is the same with Parent_directory//Child_directory and Parent_directory////Child_directory.
    # So, by adding extra '/' it does not affect the searched directory. On the contrary, without the '/', the program (due to the use of grep{-d}) cannot recognise the input as a directory.
    # With the use of a '/' we ensure that the grep{-d} will read a directory even though the user has not included the '/' at the end. 
    # By adding one more '/' the 'cleansing' of the whole path becomes easier, as whatever before the '//' (or the '///') is replaced by './' .
    # This way, the children directories are shown like ./Child_directory. 
    my $sub_dir = $dir . '//*';

    # Get the children directories by the use of grep{-d}.
    my @directories = grep{-d} glob $sub_dir;
    
    # Replace the directory with a ./ in order to be more clear which the sub-directories are. 
    # Find whatever is before the '//' and replace it with the './' .  
    s/(.*[^(\/\/)]*)(\/.*)$/\.$2/ for @directories;

    # If child directories exist, show them. Else print that there are no sub-directories. 
    print "\n\n";
    if(@directories) {
        print("-----Directories-----\n");
        print_files(\@directories);
    }
    else{
        print("The $dir does not contain any sub-directories");
    }
    print("\n\n");
}

sub r_search_files{
    # Get the:
        # @files
        # the regex
    # Only return the files that comply with the regex
    my ($files, $search_term) = @_;

    my @files = grep{/$search_term/} @$files;

    return @files;
}

sub ext_group_files {
    # Get the files
    my $files = shift;

    # Store all the extensions.
    my @extensions;
    for my $file (@$files) {
        if ($file =~ /.+\.(.+)/){
            push(@extensions, $1);
        }
    }
    # Remove the duplicates and sort the extensions alphabetically.
    @extensions = uniq(@extensions);
    @extensions = sort @extensions;

    # Print each extension (uppercase) and its files
    for my $extension (@extensions){

        my @group_files = grep{/^.+\.$extension/} @$files;
        print("\n----- " . uc $extension . " -----\n");
        print_length(\@group_files);

        print_files(\@group_files);
    }
}

sub uniq {
    my %seen;
    grep !$seen{$_}++, @_;
}


sub group_files {
    # Get the: 
        # a) @files
        # b) if the -g argument is passed
    my ($files, $opt_g) = @_;

    print("\n\n");

    ##### PDF #####
    my @pdfs = grep{/\.pdf$/} @$files;
    if(@pdfs) {
        print("-----PDF-----\n");
        print_length(\@pdfs);
        print_files(\@pdfs);
        print("\n\n");

        # Remove them from the @files
        @$files = grep{!/\.pdf$/} @$files;
    }

    ##### DOCUMENT #####
    my $word_regex = '\.(docx?|dot[m|x]?|f?o[d|t]t|s[t|d]w|txt|rtf)$';
    my @words= grep{/$word_regex/} @$files;
    if(@words) {
        print("-----DOCUMENT-----\n");
        print_length(\@words);
        print_files(\@words);
        print("\n\n");

        # Remove them from the @files
        @$files = grep{!/$word_regex/} @$files;
    }

    ##### SPREADSHEET #####
    my $excel_regex = '\.(xls[x?]|o[d|t]s|s[d|x]c)$';
    my @excels = grep{/$excel_regex/} @$files;
    if(@excels) {
        print("-----SPREADSHEET-----\n");
        print_length(\@excels);
        print_files(\@excels);
        print("\n\n");

        # Remove them from the @files
        @$files = grep{!/$excel_regex/} @$files;
    }

    ##### DATABASE #####
    my $database_regex = create_regex('Database');
    my @databases= grep{/$database_regex/} @$files;
    if(@databases) {
        print("-----DATABASE-----\n");
        print_length(\@databases);
        print_files(\@databases);
        print("\n\n");

    #    # Remove them from the @files
        @$files = grep{!/$database_regex/} @$files;
    }

    ##### E-BOOKS #####
    my $book_regex = create_regex('E-book');
    my @books= grep{/$book_regex/} @$files;
    if(@books) {
        print("-----BOOKS-----\n");
        print_length(\@books);
        print_files(\@books);
        print("\n\n");

    #    # Remove them from the @files
        @$files = grep{!/$book_regex/} @$files;
    }

    ##### AUDIO #####
    my $audio_regex = create_regex('Audio');
    my @audios= grep{/$audio_regex/} @$files;
    if(@audios) {
        print("-----AUDIO-----\n");
        print_length(\@audios);
        print_files(\@audios);
        print("\n\n");

    #    # Remove them from the @files
        @$files = grep{!/$audio_regex/} @$files;
    }

    ##### VIDEO #####
    my $video_regex = create_regex('Video');
    my @videos= grep{/$video_regex/} @$files;
    if(@videos) {
        print("-----VIDEO-----\n");
        print_length(\@videos);
        print_files(\@videos);
        print("\n\n");

    #    # Remove them from the @files
        @$files = grep{!/$video_regex/} @$files;
    }

    ##### EMAIL #####
    my $email_regex = create_regex('Email');
    my @emails= grep{/$email_regex/} @$files;
    if(@emails) {
        print("-----EMAIL-----\n");
        print_length(\@emails);
        print_files(\@emails);
        print("\n\n");

    #    # Remove them from the @files
        @$files = grep{!/$email_regex/} @$files;
    }

    ##### ARCHIVE/COMPRESSED #####
    my $compressed_regex = create_regex('Archive and compressed');
    my @compresseds= grep{/$compressed_regex/} @$files;
    if(@compresseds) {
        print("-----ARCHIVE/COMPRESSED-----\n");
        print_length(\@compresseds);
        print_files(\@compresseds);
        print("\n\n");

    #    # Remove them from the @files
        @$files = grep{!/$compressed_regex/} @$files;
    }

    ##### OTHERS #####
    if(@$files){
        print("-----OTHER-----\n");
    }

    if(defined($opt_g)){
        ext_group_files(\@$files);
    }
    else {
        print_length(\@$files);
        print_files(\@$files);
    }
}

sub print_length {
    my $array = shift;

    print("  ## ");
    if (scalar(@$array) == 1){
        print("1 file ##  \n")
    }
    else {
        print(scalar(@$array) . " files ##  \n\n");
    }
}

sub print_files {
    my $array = shift;

    foreach my $file (@$array) {
        print("· $file \n");
    }
}

sub create_regex {
    # Take the path and modify it accordingly
    my $path = shift;
    $path = './txt_files/' . $path . '.txt';

    # Open the text file or die;
    die "could not open $path" unless(open(my $extensions, "<", $path));
    my $regex = <$extensions>;
    close($extensions);

    # Make the regular expression for the category
    $regex = '\.(' . $regex . ')$';

    return $regex;
}

sub usage {
    print <<USAGE;
No directory given. 
It is obligatory to declare the directory. 

Example usage: perl Directory_scrapper.pl -d ~/Documents/ -r

Press perl Directory_scrapper.pl --help for help. 
USAGE
}

sub HELP_MESSAGE{
    die <<HELP;
This is a basic Perl program for grouping and nicely printing the files of a directory. 

Arguments:
-d <directory> (obligatory)
-r <regex> Search for a specific file/extension with the use of Regular Expressions. 
-a Do not group the files
-e Group the files by their extensions (separates similar files, for example xmlx and xml are considered as different extensions).
   If both -a and -e arguments are given, the files do not get grouped (considers only the -a argument)
-g For the rest of the files that are not found in any of the categories, group them by their extension (like using the -e for the rest of the files). 
    Using it with the -e argument does not make sense but the program will not show an error.
-b Show the sub-directories


Example usage:
perl Directory_scrapper.pl -d /home/Ioannis-D/Documents
    will return all the sub-directories and the files grouped by 'pdf', 'spreadsheet', 'documents', etc.

perl Directory_scrapper.pl -d ~/Documents/Master/ -r ^1st_course\.* -e 
    Will return all the files with name 1st_course organised by their extensions.

HELP
}

$Getopt::Std::STANDARD_HELP_VERSION = 1;
our $VERSION = 0.1;

main();
