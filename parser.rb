require 'csv'
require 'set'


def get_and_print_percentage(hsh, total, out)
    hsh.sort_by{|k, v| v}.reverse.each do |key, count| 
        percent = count.to_f/total*100
    out.write("     #{key} : #{percent.round(3)}%\n")
    end
end

#this function hadles age calculation
def get_age_stats(arr, f)
    f.write("\n\nAge Statistics\n\n")
    sum = 0
    arr_ages = []
    arr.each_with_index{|v, i| if v != "NA"; arr_ages.push(v.to_i) end}
    sum = arr_ages.sort.inject(0){|sum,x| sum + x }
    if arr_ages.size > 0
        f.write("mean age= #{sum/arr_ages.size}\nmedian age = #{arr[arr_ages.size/2]}\nMax Age = #{arr_ages.max}\nMin Age = #{arr_ages.min}")
    else
        f.write("mean age= NA\nmedian age = NA\nMax Age = NA\nMin Age = NA")
    end
end

#this function reduces processing time by bringing in most data in one pass
def parse_all(filename, vio, rac, sex, age)
    count = 0
    CSV.foreach(filename, headers: true, converters: %i[numeric date]) do |row|
        vio[row["violation"]] += 1
        rac[row["subject_race"]] += 1
        sex[row["subject_sex"]] += 1
        age.push(row["subject_age"])
        count += 1
    end
    count
end

#this function creates a hash of hashes to compare one field as a function of another field
#this is a generalized form of the function presented in class for taking outcomes by race
def a_by_b(filename, headera, headerb)
    result = Hash.new(0)
    all_headerb = Set.new
    CSV.foreach(filename, headers: true, converters: %i[numeric date]) do |row|
        a = row[headera]
        b = row[headerb]
        all_headerb.add(b)
        if !result.key?(a)
            result[a] = Hash.new(0)
            result[a][b] = 1
        elsif !result[a].key?(b)
            result[a][b] = 1
        else
            result[a][b] += 1
        end
    end
    result 
end

#this function takes a hash of hashes and sorts and prints it in a nice format
def sort_and_print_by_2(o, hash, tag)
    hash.each do |hsh|
        sum = 0
        if tag == "age"; hsh[1] = consolidate_age(hsh[1]) end
        hsh[1].each{|k, v| sum += v}
        o.write("\n#{hsh[0]}\n")
        get_and_print_percentage(hsh[1], sum, o)
    end
end

#This function turns ages in to more useful age ranges which can be used to more easily analyze age data
def consolidate_age(hash)
    c_10 = 0; c_20 = 0; c_30 = 0
    c_40 = 0; c_50 = 0; c_60 = 0
    c_70 = 0; c_invalid = 0
    hash.each do |k,v|
        case k
        when "NA"
            c_invalid+= v
        when 0..30
            c_10 += v
        when 30..50
            c_20 += v
        when 50..70
            c_30 += v
        when 70..200
            c_70 += v
        else
            c_invalid += 1
        end
    end
    {"Under 30" => c_10, "30-49" => c_20,"50-69" => c_30,"70 and older" => c_70, "NA or Invalid" => c_invalid}
end
    
        
#this is a helper function used for debugging
def sort_and_print(hash)
    hash.sort_by {|k, v| v}.reverse.each{|item| p item}
end

#this is now a depreciated function originally designed to parse a single header
#not used because it adds too much runtime as it is an extra perusal of the file
def parse_header(filename, header)
    result = Hash.new(0)
    CSV.foreach(filename, headers: true, converters: %i[numeric date]) do |row|
        result[row[header]] += 1
    end 
    result 
end


def output(f, field, i, total)
    f.write("\n\n#{if i == 0; "Violation"; elsif i == 1; "Subject Race"; else; "Subject Sex"end} Statistics \n\n")
    get_and_print_percentage(field, total, f)
end

#this function prints just the violations
#the actual data sets I wanted to look at didn't have violations data, so as a proof of concept 
#i built this function to print the violations for two data sets which actually have violations data
#I then commented it out when i realized i should just use the output function... obviously
# def outputv(f, field, total)
#     f.write("\n\nViolation Statistics \n\n")
#     get_and_print_percentage(field, total, f)
# end

#this function does the full dataset breakdown. it was originally in the main function but to 
#simplify main I moved this up here
def analyze_file(ind, vio, rac, sex, file, f, count, age)
    f.write("\n\n__________________________\n#{ind == 0 ? "San Francisco" : ind == 1 ? "San Diego" : "New Orleans"} State Statistics\n__________________________\n")
    [vio, rac, sex].each_with_index{|field, i| output(f, field, i, count)} 
    get_age_stats(age, f)
    f.write("\n______________\nSubject race vs stop outcome\n______________")
    sort_and_print_by_2(f, a_by_b(file, "subject_race", "outcome"), " 0 ")
    f.write("\n______________\nSubject race vs subject sex\n______________")
    sort_and_print_by_2(f, a_by_b(file, "subject_race", "subject_sex"), " 0 ")
    f.write("\n______________\nSubject race vs subject age\n______________")
    sort_and_print_by_2(f, a_by_b(file, "subject_race", "subject_age"), "age")
end 

#in my experience it is common by convention in python to have a "main" function thus making the only piece of code outside a function
#the call of the main function and the if __FILE__ == $0 structure.
def main()
    oFile = "outputparser"
    sd = 'ca_san_francisco_2020_04_01.csv'
    sf = 'ca_san_diego_2020_04_01.csv'
    no = 'la_new_orleans_2020_04_01.csv'
    chi = 'il_chicago_2020_04_01.csv'
    mt = 'mt_statewide_2020_04_01.csv'

    [sd, sf, no, chi, mt].each_with_index do |file, ind| 
        vio = Hash.new(0); 
        rac = Hash.new(0); 
        sex = Hash.new(0);
        age = []
        count = parse_all(file, vio, rac, sex, age); 

        File.open("#{oFile}#{file}.txt", "w"){|f| f.write("")}
        File.open("#{oFile}#{file}.txt", "a") do |f|
            if (ind < 3); analyze_file(ind, vio, rac, sex, file, f, count, age)
            else 
                f.write("#{if file == chi; "Chicago"; else; "Montana State"end} Statistics\n__________________________________________")
                output(f, vio, 0, count)
            end
        end 
    end
end


if __FILE__ == $0
    main
end