## need to initially populate things
source("~/pmg/GW-refactor/questionr/R/config.R")
## projects
proj_tbl <- questionr:::project_table()
proj_tbl$read(lock=TRUE)
proj_id <- questionr:::project_new(proj_tbl,
                       "~/tmp/kitchen.Rmd",
                                   name="Sample project 1",
                       author="jverzani",
                       public="yes")
proj_id_1 <- questionr:::project_new(proj_tbl,
                                     name="Sample project 2",
                         "~/tmp/kitchen1.Rmd",
                         author="jverzani",
                         public="yes")
proj_tbl$write()

## classes



## sections
sec_tbl <- questionr:::section_table(lock=TRUE)
sec_id <- questionr:::section_new(sec_tbl,
                                  name="<9999>",
                                  class="MTH 214",
                                  projects=c(proj_id, proj_id_1))
sec_tbl$write()

## auth table
a_tbl <- questionr:::auth_table(lock=TRUE)

t_id <- questionr:::auth_new(a_tbl,
                 identifier="jverzani@gmail.com",
                 name="JOhn Verzani",
                 roles=c("admin", "teacher")
                 )
s_id <- questionr:::auth_new(a_tbl,
                 identifier="jverzani@yahoo.com",
                 name="Student john",
                 roles=c("student")
                 )
a_tbl$write()

## student
stud_tbl <- questionr:::student_table(lock=TRUE)
questionr:::student_new(stud_tbl, id=s_id)
questionr:::student_add_section(stud_tbl, id=s_id, section_id=sec_id)
stud_tbl$write()



## teacher
teach_tbl <- questionr:::teacher_table(lock=TRUE)
questionr:::teacher_new(teach_tbl, t_id, sec_id)
teach_tbl$write()


## messages
msg_t <- questionr:::message_table(lock=TRUE)
m_id <- questionr:::message_new(msg_t,
                    "error",
                    "Title:",
                    "some new message ...")
msg_t$write()

sid <- "OBHJWWLOLK"
questionr:::message_add_students(id=m_id, users=sid)


