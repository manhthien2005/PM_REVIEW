const fs = require('fs');
const path = require('path');

const jiraDir = 'D:/DoAn2/VSmartwatch/PM_REVIEW/Resources/TASK/JIRA';
const dateStr = new Date().toISOString().split('T')[0];
const reportPath = `D:/DoAn2/VSmartwatch/PM_REVIEW/Task/Backlog_Review_${dateStr}.md`;

let report = `# Báo Cáo Tiến Độ Sprint — ${new Date().toLocaleDateString('vi-VN')}\n\n`;
report += `## Bảng Tổng Quan\n\n`;
report += `| Sprint | Tổng EP | Hoàn thành | Tỉ lệ Tiến độ tính theo SP | Tiến độ AC (Story) |\n`;
report += `| -------- | ------- | ---------- | -------------------------- | ------------------ |\n`;

let details = `## ⚠️ Mục Có Rủi Ro / Cảnh Báo\n\n`;
let detailedStories = `## Phân Tích Stories Nổi Bật\n\n`;

const sprints = fs.readdirSync(jiraDir).filter(d => d.startsWith('Sprint-'));

for(const s of sprints) {
    const sprintDir = path.join(jiraDir, s);
    const sprintFile = path.join(sprintDir, '_SPRINT.md');
    if (!fs.existsSync(sprintFile)) continue;
    
    const sprintContent = fs.readFileSync(sprintFile, 'utf8');
    const epicsLines = sprintContent.split('\n').filter(l => l.match(/^- \[[x ]\] EP\d+/));
    const totalEpics = epicsLines.length;
    const completedEpics = epicsLines.filter(l => l.startsWith('- [x]')).length;
    
    let sprintTotalSP = 0;
    let sprintCompletedSP = 0;
    
    let sprintTotalAC = 0;
    let sprintCompletedAC = 0;
    
    const epicFolders = fs.readdirSync(sprintDir, {withFileTypes: true}).filter(d => d.isDirectory()).map(d => d.name);
    
    for (const epic of epicFolders) {
        const storiesFile = path.join(sprintDir, epic, 'STORIES.md');
        if (!fs.existsSync(storiesFile)) continue;
        
        const storiesContent = fs.readFileSync(storiesFile, 'utf8');
        // match only AC lines which are usually like "- [ ] " or "- [x] " after "Acceptance Criteria:"
        const acLines = storiesContent.split('\n').filter(l => l.match(/^- \[[xX ]\] /));
        const totalAC = acLines.length;
        const checkedAC = acLines.filter(l => l.match(/^- \[[xX]\]/)).length;
        
        sprintTotalAC += totalAC;
        sprintCompletedAC += checkedAC;
        
        let epicSP = 0;
        const epicLine = epicsLines.find(l => l.includes(epic));
        if (epicLine) {
            const spMatch = epicLine.match(/\((\d+)\s*SP\)/i);
            if (spMatch) epicSP = parseInt(spMatch[1], 10);
        } else {
            // Try to extract SP from stories
            const spMatches = storiesContent.match(/\*\*SP:\*\*\s*(\d+)/g);
            if(spMatches) {
                epicSP = spMatches.reduce((acc, curr) => {
                    const match = curr.match(/\*\*SP:\*\*\s*(\d+)/);
                    return acc + (match ? parseInt(match[1], 10) : 0);
                }, 0);
            }
        }
        
        sprintTotalSP += epicSP;
        
        if (epicLine && epicLine.startsWith('- [x]')) {
             sprintCompletedSP += epicSP;
        } else if (totalAC > 0) {
             sprintCompletedSP += Math.round(epicSP * (checkedAC / totalAC));
        }
        
        if (totalAC > 0 && checkedAC === 0) {
            details += `- **${epic} (${s})**: Chưa bắt đầu (0/${totalAC} AC).\n`;
        } else if (totalAC > 0 && checkedAC < totalAC) {
            details += `- **${epic} (${s})**: Đang thực hiện (${checkedAC}/${totalAC} AC hoàn thành).\n`;
        } else if (totalAC > 0 && checkedAC === totalAC) {
             detailedStories += `- **${epic} (${s})**: Đã hoàn thành toàn bộ (${checkedAC}/${totalAC} AC).\n`;
        }
    }
    
    const spRate = sprintTotalSP > 0 ? Math.round((sprintCompletedSP / sprintTotalSP) * 100) : 0;
    const acRate = sprintTotalAC > 0 ? Math.round((sprintCompletedAC / sprintTotalAC) * 100) : 0;
    
    report += `| ${s} | ${totalEpics}       | ${completedEpics}          | ~${spRate}%                        | ~${acRate}% (${sprintCompletedAC}/${sprintTotalAC}) |\n`;
}

report += `\n` + details + `\n` + detailedStories;

fs.writeFileSync(reportPath, report);
console.log('Report generated at:', reportPath);
