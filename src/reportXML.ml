(*
 * This file is part of Bisect.
 * Copyright (C) 2008-2009 Xavier Clerc.
 *
 * Bisect is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * Bisect is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *)

let dtd = [
  "<!ELEMENT bisect-report (summary,file*)>" ;
  "" ;
  "<!ELEMENT file (summary,point*)>" ;
  "<!ATTLIST file path CDATA #REQUIRED>" ;
  "" ;
  "<!ELEMENT summary (element*)>" ;
  "" ;
  "<!ELEMENT element EMPTY>" ;
  "<!ATTLIST element kind CDATA #REQUIRED>" ;
  "<!ATTLIST element count CDATA #REQUIRED>" ;
  "<!ATTLIST element total CDATA #REQUIRED>" ;
  "" ;
  "<!ELEMENT point EMPTY>" ;
  "<!ATTLIST point offset CDATA #REQUIRED>" ;
  "<!ATTLIST point count CDATA #REQUIRED>" ;
  "<!ATTLIST point kind CDATA #REQUIRED>" ;
  ""
]

let xml_header = "<?xml version=\"1.0\" encoding=\"iso-8859-1\"?>\n"

let time_comment () =
  Printf.sprintf "<!-- generated by Bisect %s (%s) on %s -->\n"
    ReportUtils.version
    ReportUtils.url
    (ReportUtils.current_time ())

let make () =
  object (self)
    method header = xml_header ^ (time_comment ()) ^ "<bisect-report>\n"
    method footer = "</bisect-report>\n"
    method summary s = self#sum "  " s
    method file_header f = Printf.sprintf "  <file path=\"%s\">\n" f
    method file_footer _ = Printf.sprintf "  </file>\n"
    method file_summary s = self#sum "    " s
    method point ofs nb k = Printf.sprintf "    <point offset=\"%d\" count=\"%d\" kind=\"%s\"/>\n" ofs nb (Common.string_of_point_kind k)
    method private sum tabs s =
      let line k x y =
        Printf.sprintf "<element kind=\"%s\" count=\"%d\" total=\"%d\"/>" k x y in
      let lines =
        List.map
          (fun (k, v) ->
            line (Common.string_of_point_kind k) v.ReportStat.count v.ReportStat.total)
          s in
      let x, y = ReportStat.summarize s in
      tabs ^ "<summary>\n  " ^ tabs ^
      (String.concat ("\n  " ^ tabs) lines) ^
      "\n  " ^ tabs ^ (line "total" x y) ^
      "\n" ^ tabs ^ "</summary>\n"
  end

type emma_category =
  | Class
  | Method
  | Block
  | Line

let emma_categories = [
  Class ;
  Method ;
  Block ;
  Line
]

let string_of_emma_category = function
  | Class -> "class, %"
  | Method -> "method, %"
  | Block -> "block, %"
  | Line -> "line, %"

let emma_category_of_point_kind = function
  | Common.Binding -> Block
  | Common.Sequence -> Block
  | Common.For -> Block
  | Common.If_then -> Block
  | Common.Try -> Block
  | Common.While -> Block
  | Common.Match -> Block
  | Common.Class_expr -> Class
  | Common.Class_init -> Class
  | Common.Class_meth -> Method
  | Common.Class_val -> Class
  | Common.Toplevel_expr -> Line
  | Common.Lazy_operator -> Block

let make_emma () =
  object
    method header =
      xml_header
      ^ (time_comment ())
      ^ "<report>\n"
      ^ "  <stats>\n"
      ^ "    <packages value=\"1\"/>\n"
      ^ "    <classes value=\"1\"/>\n"
      ^ "    <methods value=\"1\"/>\n"
      ^ "    <srcfiles value=\"1\"/>\n"
      ^ "    <srclines value=\"1\"/>\n"
      ^ "  </stats>\n"
    method footer = "</report>\n"
    method summary s =
      let (++) = ReportUtils.(++) in
      let stats =
	List.map
	  (fun x -> x, { ReportStat.count = 0; ReportStat.total = 0 })
	  emma_categories in
      List.iter
	(fun (k, v) ->
	  let x = List.assoc (emma_category_of_point_kind k) stats in
	  x.ReportStat.count <- x.ReportStat.count ++ v.ReportStat.count;
	  x.ReportStat.total <- x.ReportStat.total ++ v.ReportStat.total)
	s;
      let lines =
	List.map
	  (fun (k, v) ->
	    let count, total = 
	      if v.ReportStat.total > 0 then
		v.ReportStat.count, v.ReportStat.total
	      else
		1, 1 in
	    let percentage = (count * 100) / total in
	    Printf.sprintf "      <coverage type=\"%s\" value=\"%d%%%s(%d/%d)\"/>\n"
	      (string_of_emma_category k)
	      percentage
	      (if percentage = 100 then " " else if percentage < 10 then "   " else "  ")
	      count
	      total)
	  stats in
      "  <data>\n"
      ^ "    <all name=\"all classes\">\n"
      ^ (String.concat "" lines)
      ^ "    </all>\n"
      ^ "  </data>\n"
    method file_header _ = ""
    method file_footer _ = ""
    method file_summary _ = ""
    method point _ _ _ = ""
  end