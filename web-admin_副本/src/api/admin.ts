import request from './request'

export function login(studentId: string, password: string) {
  return request.post('/user/login', { studentId, password })
}

export function getSemesters() {
  return request.get('/admin/semester/list')
}

export function addSemester(data: any) {
  return request.post('/admin/semester/add', data)
}

export function updateSemester(id: number, data: any) {
  return request.put(`/admin/semester/${id}`, data)
}

export function setCurrentSemester(id: number) {
  return request.put(`/admin/semester/${id}/set-current`)
}

export function deleteSemester(id: number) {
  return request.delete(`/admin/semester/${id}`)
}

export function getClasses(grade?: string, collegeId?: number, majorId?: number) {
  const params: any = {}
  if (grade) params.grade = grade
  if (collegeId) params.collegeId = collegeId
  if (majorId) params.majorId = majorId
  return request.get('/admin/class/list', { params })
}

export function getColleges() {
  return request.get('/admin/college/list')
}

export function getMajors(collegeId?: number) {
  const params: any = {}
  if (collegeId) params.collegeId = collegeId
  return request.get('/admin/major/list', { params })
}

export function getGrades() {
  return request.get('/admin/class/grades')
}

export function addClass(data: any) {
  return request.post('/admin/class/add', data)
}

export function batchAddClass(data: any) {
  return request.post('/admin/class/batch-add', data)
}

export function deleteClassByGrade(grade: string) {
  return request.delete('/admin/class/by-grade', { params: { grade } })
}

export function deleteClass(id: number) {
  return request.delete(`/admin/class/${id}`)
}

export function getTimetableByClass(classId: number, semesterId: number) {
  return request.get('/admin/timetable/class', { params: { classId, semesterId } })
}

export function importSchedule(file: File, classId: number, semesterId: number) {
  const formData = new FormData()
  formData.append('file', file)
  formData.append('classId', String(classId))
  formData.append('semesterId', String(semesterId))
  return request.post('/admin/timetable/import', formData, {
    headers: { 'Content-Type': 'multipart/form-data' },
  })
}

export function getAnnouncements() {
  return request.get('/admin/announcement/list')
}

export function publishAnnouncement(data: any) {
  return request.post('/admin/announcement/publish', data)
}

export function updateAnnouncement(id: number, data: any) {
  return request.put(`/admin/announcement/${id}`, data)
}

export function deleteAnnouncement(id: number) {
  return request.delete(`/admin/announcement/${id}`)
}
